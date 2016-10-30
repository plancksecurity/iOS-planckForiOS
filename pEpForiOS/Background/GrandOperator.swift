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
     Asynchronously create local special folders, like Outbox, Sent etc.

     - parameter accountEmail: The email of the account those folders belong to.
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func createSpecialLocalFolders(_ accountEmail: String,
                                   completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asynchronously verifies the given connection. Tests for IMAP and SMTP. The test is considered
     a success when authentication was successful.
     */
    func verifyConnection(imapConnectInfo: EmailConnectInfo, smtpConnectInfo: EmailConnectInfo,
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
    open let coreDataUtil: CoreDataUtil

    fileprivate let verifyConnectionQueue = OperationQueue.init()
    fileprivate let backgroundQueue = OperationQueue.init()

    /**
     The main model (for use on the main thread)
     */
    fileprivate lazy var model: ICdModel = {
        return CdModel.init(context: self.coreDataUtil.managedObjectContext)
    }()

    /**
     Used for storing running flag sync operations to avoid duplicate work.
     */
    fileprivate var flagSyncOperations = [String: BaseOperation]()

    public init(connectionManager: ConnectionManager, coreDataUtil: CoreDataUtil) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
        self.connectionManager.grandOperator = self
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
        verifyConnectionQueue.cancelAllOperations()
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
            connectInfo: connectInfo, coreDataUtil: coreDataUtil,
            connectionManager: connectionManager, onlyUpdateIfNecessary: false)
        kickOffConcurrentOperation(operation: op, completionBlock: completionBlock)
    }

    open func fetchEmailsAndDecryptImapSmtp(
        connectInfos: [EmailConnectInfo], folderName: String?,
        completionBlock: GrandOperatorCompletionBlock?) {
        var operations = [BaseOperation]()
        var fetchOperations = [BaseOperation]()

        for connectInfo in connectInfos {
            operations.append(CreateLocalSpecialFoldersOperation.init(
                coreDataUtil: coreDataUtil,
                accountEmail: connectInfo.userId))
            operations.append(FetchFoldersOperation.init(
                connectInfo: connectInfo, coreDataUtil: coreDataUtil,
                connectionManager: connectionManager, onlyUpdateIfNecessary: true))

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

    open func createSpecialLocalFolders(_ accountEmail: String,
                                          completionBlock: GrandOperatorCompletionBlock?) {
        let op = CreateLocalSpecialFoldersOperation.init(coreDataUtil: coreDataUtil,
                                                         accountEmail: accountEmail)
        kickOffConcurrentOperation(operation: op, completionBlock: completionBlock)
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

    open func verifyConnection(imapConnectInfo: EmailConnectInfo, smtpConnectInfo: EmailConnectInfo,
                               completionBlock: GrandOperatorCompletionBlock?) {
        let op1 = VerifyImapConnectionOperation.init(grandOperator: self,
                                                     connectInfo: imapConnectInfo)
        let op2 = VerifySmtpConnectionOperation.init(grandOperator: self,
                                                     connectInfo: smtpConnectInfo)

        var finished1 = false
        var finished2 = false

        // Since the completion blocks retain op1 and op2, respectively,
        // a cyclic dependency is created that prevents the deallocation of both.
        // This must be resolved when both have finished.
        let completion1 = {
            GCD.onMain({ // serialize
                finished1 = true
                self.handleVerificationCompletionFinished1(finished1, finished2: finished2,
                    op1: op1, op2: op2,
                    completionBlock: completionBlock)
            })
        }
        let completion2 = {
            GCD.onMain({ // serialize
                finished2 = true
                self.handleVerificationCompletionFinished1(finished1, finished2: finished2,
                    op1: op1, op2: op2,
                    completionBlock: completionBlock)
            })
        }

        op1.completionBlock = completion1
        op2.completionBlock = completion2

        verifyConnectionQueue.addOperation(op1)
        verifyConnectionQueue.addOperation(op2)
    }

    open func sendMail(_ message: CdMessage, account: CdAccount,
                         completionBlock: GrandOperatorCompletionBlock?) {
        let encryptionData = EncryptionData.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil,
            coreDataMessageID: message.objectID, accountEmail: account.email)

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
        let hashable = folder.hashableID()
        var operation: BaseOperation? = flagSyncOperations[hashable]
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
        assertionFailure("GrandOperator.verify not implemented")
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
