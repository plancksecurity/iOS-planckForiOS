//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public typealias GrandOperatorCompletionBlock = (_ error: NSError?) -> Void

public protocol IGrandOperator: class {
    var coreDataUtil: CoreDataUtil { get }

    var connectionManager: ConnectionManager { get }

    /**
     Tests will use this to make sure there are no retain cycles.
     */
    func shutdown()

    /**
     Will *serially* invoke a list of operations, gathering all errors, and calling
     the completion block when the last operation has finished.
     *All* operations are executed, even if one in the chain fails. If there are errors,
     only the first will be reported to the completion block.
     This is most useful if the scheduled operations don't have direct dependencies to
     each other.
     - parameter operations: The list of operations to invoke in serial order.
     - parameter completionBlock: The block to call when all ops have finished, together with
     any error that ocurred.
     */
    func chainOperations(_ operations: [BaseOperation],
                         completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asynchronously fetches the folder list.

     - parameter connectInfo: Denotes the server and other connection parameters
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func fetchFolders(_ connectInfo: EmailConnectInfo, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asychronously fetches mails for the given `EmailConnectInfo`s
     and the given folder name and stores them into the persistent store.
     Will also decrypt them, and fetch folders if necessary.

     - parameter connectInfo: Denotes the server and other connection parameters
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func fetchEmailsAndDecryptImapSmtp(
        connectInfos: [EmailConnectInfo], folderName: String?,
        completionBlock: GrandOperatorCompletionBlock?)

    /**
     Sends the given mail via SMTP. Also saves it into the drafts folder. You
     might have to trigger a fetch for that mail to appear in your drafts folder.
     */
    func sendMail(_ email: CdMessage, account: CdAccount, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Saves the given email as a draft, both on the server and locally.
     */
    func saveDraftMail(_ message: CdMessage, account: CdAccount,
                       completionBlock: GrandOperatorCompletionBlock?)

    /**
     Syncs all mails' flags in the given folder that are out of date to the server.
     */
    func syncFlagsToServerForFolder(_ folder: CdFolder,
                                    completionBlock: GrandOperatorCompletionBlock?)

    /**
     Creates a folder with the given properties if it doesn't exist,
     both locally and on the server.
     */
    func createFolderOfType(_ account: CdAccount, folderType: FolderType,
                            completionBlock: GrandOperatorCompletionBlock?)

    /**
     Deletes the given folder, both locally and remotely.
     */
    func deleteFolder(_ folder: CdFolder, completionBlock: GrandOperatorCompletionBlock?)
}

open class GrandOperator: IGrandOperator {
    public var sendLayerDelegate: SendLayerDelegate? = nil

    /**
     Key for accessing the model in thread-local storage.
     */
    static let kOperationModel = "kOperationModel"

    let comp = "GrandOperator"

    open let connectionManager: ConnectionManager
    open let coreDataUtil = CoreDataUtil()

    fileprivate let verificationQueue = OperationQueue()
    fileprivate let backgroundQueue = OperationQueue()

    /**
     The main model (for use on the main thread)
     */
    fileprivate lazy var model: ICdModel = {
        return CdModel.init(context: self.coreDataUtil.defaultContext())
    }()

    /**
     Used for storing running flag sync operations to avoid duplicate work.
     */
    fileprivate var flagSyncOperations = [String: BaseOperation]()

    public init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.connectionManager.grandOperator = self
    }

    public convenience init() {
        self.init(connectionManager: ConnectionManager())
    }

    open func chainOperations(_ operations: [BaseOperation],
                                completionBlock: GrandOperatorCompletionBlock?) {
        // Add dependencies
        var lastOp: Operation? = nil
        for op in operations {
            if let op1 = lastOp {
                op.addDependency(op1)
            }
            backgroundQueue.addOperation(op)
            lastOp = op
        }

        // Since they all have a serial dependency, it's sufficient to monitor the last op
        // for completion.
        var errors: [NSError] = []
        if let lastOp = operations.last {
            lastOp.completionBlock = {
                GCD.onMain() {
                    lastOp.completionBlock = nil
                    for op in operations {
                        errors.append(contentsOf: op.errors)
                    }
                    // Only the first error will be reported
                    completionBlock?(errors.first)
                }
            }
        }
    }

    open func shutdown() {
        connectionManager.shutdown()
    }

    func kickOffConcurrentOperation(operation op: BaseOperation,
                                    completionBlock: GrandOperatorCompletionBlock?) {
        op.completionBlock = {
            // Resolve cyclic dependency
            op.completionBlock = nil

            // Even for operations running on the main thread with main loop,
            // that block will be called on some background queue.
            GCD.onMain() {
                completionBlock?(op.errors.first)
            }
        }
        op.start()
    }

    open func fetchFolders(_ connectInfo: EmailConnectInfo,
                             completionBlock: GrandOperatorCompletionBlock?) {
        let op = FetchFoldersOperation.init(
            connectInfo: connectInfo, connectionManager: connectionManager,
            onlyUpdateIfNecessary: false)
        kickOffConcurrentOperation(operation: op, completionBlock: completionBlock)
    }

    open func fetchEmailsAndDecryptImapSmtp(
        connectInfos: [EmailConnectInfo], folderName: String?,
        completionBlock: GrandOperatorCompletionBlock?) {
        var operations = [BaseOperation]()
        var fetchOperations = [BaseOperation]()

        for connectInfo in connectInfos {
            guard let account = Record.Context.default.object(with: connectInfo.accountObjectID)
                as? MessageModel.CdAccount else {
                    completionBlock?(Constants.errorCannotFindAccount(component: comp))
                    return
            }
            operations.append(CreateLocalSpecialFoldersOperation(account: account))
            operations.append(FetchFoldersOperation.init(
                connectInfo: connectInfo, connectionManager: connectionManager,
                onlyUpdateIfNecessary: true))

            let fetchOp = PrefetchEmailsOperation.init(
                grandOperator: self, connectInfo: connectInfo,
                folder: folderName)
            fetchOperations.append(fetchOp)
            operations.append(fetchOp)
        }

        // Wait with the decryption until all mails have been downloaded.
        let decryptOp = DecryptMailOperation.init(coreDataUtil: coreDataUtil)
        for fetchOp in fetchOperations {
            decryptOp.addDependency(fetchOp)
        }
        operations.append(decryptOp)

        chainOperations(
            operations, completionBlock: { error in
                // This completion block should already have been scheduled on the main queue
                // by chainOperations.
                completionBlock?(error)
        })
    }

    func handleVerificationCompletionFinished1(_ finished1: Bool, finished2: Bool,
                                      op1: BaseOperation, op2: BaseOperation,
                                      completionBlock: GrandOperatorCompletionBlock?) {
        if finished1 && finished2 {
            // Dissolve the cyclic dependency between the operation,
            // the completion block, and back.
            op1.completionBlock = nil
            op2.completionBlock = nil

            var error: NSError? = nil
            error = op1.errors.first
            if error == nil {
                error = op2.errors.first
            }

            // This is already scheduled on the main queue
            completionBlock?(error)
        }
    }

    /**
     Asynchronously verifies the given `EmailConnectInfo`s.
     */
    open func verify(
        account: MessageModel.CdAccount, emailConnectInfos: [EmailConnectInfo: CdServerCredentials],
        completionBlock: GrandOperatorCompletionBlock?) {

        // The operations tha will be run
        var ops = [VerifyServiceOperation]()

        /// Creates a completion block for a verification operation.
        /// Has to find out if the verification was successful, and if it was, will set
        /// `needsVerification` to `false`.
        func mkCompletionBlock(op: VerifyServiceOperation,
                               credential: CdServerCredentials) -> (() -> Void)? {
            let ctx = credential.managedObjectContext!
            return {
                if !op.hasErrors() {
                    ctx.performAndWait {
                        credential.needsVerification = false
                    }
                }
            }
        }

        /// Add a `VerifyServiceOperation` to the operations to run, and give it a completion
        /// block created with `mkCompletionBlock`.
        func add(operation: VerifyServiceOperation, credentials: CdServerCredentials?) {
            guard let cred = credentials else {
                Log.error(component: comp,
                          errorString: "Cannot add VerifyServiceOperation without credentials")
                return
            }
            operation.completionBlock = mkCompletionBlock(op: operation, credential: cred)
            ops.append(operation)
        }

        for ci in emailConnectInfos.keys {
            if let prot = ci.emailProtocol {
                switch prot {
                case .imap:
                    add(operation: VerifyImapConnectionOperation(
                        grandOperator: self, connectInfo: ci),
                        credentials:  emailConnectInfos[ci]!)
                case .smtp:
                    add(operation: VerifySmtpConnectionOperation(
                        grandOperator: self, connectInfo: ci),
                        credentials:  emailConnectInfos[ci]!)
                }
            }
        }

        verificationQueue.batch(operations: ops, completionBlock: {
            var error: NSError?
            for op in ops {
                if op.hasErrors() {
                    error = op.errors.last
                    break
                }
            }
            if error == nil {
                let ctx = account.managedObjectContext!
                ctx.performAndWait {
                    account.needsVerification = false
                    Record.save(context: ctx)
                }
            }
            completionBlock?(error)
        })
    }

    open func sendMail(_ message: CdMessage, account: CdAccount,
                         completionBlock: GrandOperatorCompletionBlock?) {
        let encryptionData = EncryptionData.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil,
            coreDataMessageID: message.objectID, accountEmail: account.connectInfo.userName)

        let opEncrypt = EncryptMailOperation.init(encryptionData: encryptionData)
        let opSend = SendMailOperation.init(encryptionData: encryptionData)
        let opCreateSentFolder = CheckAndCreateFolderOfTypeOperation.init(
            account: account, folderType: .sent, connectionManager: connectionManager,
            coreDataUtil: coreDataUtil)
        let opSaveSent = SaveSentMessageOperation.init(encryptionData: encryptionData)

        opSaveSent.addDependency(opSend)
        opSaveSent.addDependency(opCreateSentFolder)
        opSend.addDependency(opEncrypt)

        opSaveSent.completionBlock = {
            GCD.onMain() {
                var firstError: NSError?
                for op in [opEncrypt, opSend, opCreateSentFolder, opSaveSent] {
                    if let err = op.errors.first {
                        firstError = err
                        break
                    }
                }
                completionBlock?(firstError)
            }
        }

        backgroundQueue.addOperation(opEncrypt)
        backgroundQueue.addOperation(opSend)
        backgroundQueue.addOperation(opCreateSentFolder)
        backgroundQueue.addOperation(opSaveSent)
    }

    open func saveDraftMail(_ message: CdMessage, account: CdAccount,
                              completionBlock: GrandOperatorCompletionBlock?) {
        let opCreateDraftFolder = CheckAndCreateFolderOfTypeOperation.init(
            account: account, folderType: .drafts, connectionManager: connectionManager, coreDataUtil: coreDataUtil)

        let opStore = AppendSingleMessageOperation.init(
            message: message, account: account, folderType: .drafts,
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
        opStore.completionBlock = {
            GCD.onMain() {
                var firstError: NSError?
                for op in [opCreateDraftFolder, opStore] {
                    if let err = op.errors.first {
                        firstError = err
                        break
                    }
                }
                completionBlock?(firstError)
            }
        }
        opStore.addDependency(opCreateDraftFolder)

        backgroundQueue.addOperation(opCreateDraftFolder)
        backgroundQueue.addOperation(opStore)
    }

    open func syncFlagsToServerForFolder(_ folder: CdFolder,
                                           completionBlock: GrandOperatorCompletionBlock?) {
        
        let uuid = folder.uuid!
        var operation: BaseOperation? = flagSyncOperations[uuid]
        let blockOrig = operation?.completionBlock

        if operation == nil {
            operation = SyncFlagsToServerOperation.init(
                folder: folder, connectionManager: connectionManager,
                coreDataUtil: coreDataUtil)
        }

        operation?.completionBlock = {
            GCD.onMain() {
                blockOrig?()
                let firstError = operation?.errors.first
                completionBlock?(firstError)
            }
        }
        if let op = operation {
            backgroundQueue.addOperation(op)
        }
    }

    open func createFolderOfType(_ account: CdAccount, folderType: FolderType,
                                   completionBlock: GrandOperatorCompletionBlock?) {
        let op = CheckAndCreateFolderOfTypeOperation.init(
            account: account, folderType: folderType,
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
        op.completionBlock = {
            GCD.onMain() {
                completionBlock?(op.errors.first)
            }
        }
        backgroundQueue.addOperation(op)
    }

    open func deleteFolder(_ folder: CdFolder,
                             completionBlock: GrandOperatorCompletionBlock?) {
        let op = DeleteFolderOperation.init(
            folder: folder, connectionManager: connectionManager,
            coreDataUtil: coreDataUtil)
        op.completionBlock = {
            GCD.onMain() {
                completionBlock?(op.errors.first)
            }
        }
        backgroundQueue.addOperation(op)
    }
}

// MARK: - SendLayerProtocol

extension GrandOperator: SendLayerProtocol {
    public func verify(account: MessageModel.CdAccount,
                       completionBlock: SendLayerCompletionBlock?) {
        let cis = account.emailConnectInfos
        verify(account: account, emailConnectInfos: cis, completionBlock: { error in
            completionBlock?(error)
        })
    }

    public func send(message: MessageModel.CdMessage, completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("GrandOperator.send not implemented")
    }

    public func saveDraft(message: MessageModel.CdMessage,
                          completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("GrandOperator.saveDraft not implemented")
    }

    public func syncFlagsToServer(folder: MessageModel.CdFolder,
                                  completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("GrandOperator.syncFlagsToServer not implemented")
    }

    public func create(folderType: FolderType, account: MessageModel.CdAccount,
                       completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("not implemented")
    }

    public func delete(folder: MessageModel.CdFolder, completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("not implemented")
    }

    public func delete(message: MessageModel.CdMessage,
                       completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("not implemented")
    }
}
