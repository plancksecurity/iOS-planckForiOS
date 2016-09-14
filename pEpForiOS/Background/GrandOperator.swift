//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public typealias GrandOperatorCompletionBlock = (error: NSError?) -> Void

public protocol IGrandOperator: class {
    var coreDataUtil: ICoreDataUtil { get }

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
    func chainOperations(operations: [BaseOperation],
                         completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asynchronously fetches the folder list.

     - parameter connectInfo: Denotes the server and other connection parameters
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func fetchFolders(connectInfo: ConnectInfo, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asychronously fetches mails for the given `ConnectInfo`s
     and the given folder name and stores them into the persistent store.
     Will also decrypt them, and fetch folders if necessary.

     - parameter connectInfo: Denotes the server and other connection parameters
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func fetchEmailsAndDecryptConnectInfos(
        connectInfos: [ConnectInfo], folderName: String?,
        completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asynchronously create local special folders, like Outbox, Sent etc.

     - parameter accountEmail: The email of the account those folders belong to.
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func createSpecialLocalFolders(accountEmail: String,
                                   completionBlock: GrandOperatorCompletionBlock?)

    /**
     Asynchronously verifies the given connection. Tests for IMAP and SMTP. The test is considered
     a success when authentication was successful.
     */
    func verifyConnection(connectInfo: ConnectInfo, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Sends the given mail via SMTP. Also saves it into the drafts folder. You
     might have to trigger a fetch for that mail to appear in your drafts folder.
     */
    func sendMail(email: IMessage, account: Account, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Saves the given email as a draft, both on the server and locally.
     */
    func saveDraftMail(message: IMessage, account: IAccount,
                       completionBlock: GrandOperatorCompletionBlock?)

    /**
     Syncs all mails' flags in the given folder that are out of date to the server.
     */
    func syncFlagsToServerForFolder(folder: IFolder,
                                    completionBlock: GrandOperatorCompletionBlock?)
}

public class GrandOperator: IGrandOperator {
    /**
     Key for accessing the model in thread-local storage.
     */
    static let kOperationModel = "kOperationModel"

    let comp = "GrandOperator"

    public let connectionManager: ConnectionManager
    public let coreDataUtil: ICoreDataUtil

    private let verifyConnectionQueue = NSOperationQueue.init()
    private let backgroundQueue = NSOperationQueue.init()

    /**
     The main model (for use on the main thread)
     */
    private lazy var model: IModel = {
        return Model.init(context: self.coreDataUtil.managedObjectContext)
    }()

    /**
     Used for storing running flag sync operations to avoid duplicate work.
     */
    private var flagSyncOperations = [String: BaseOperation]()

    public init(connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
        self.connectionManager.grandOperator = self
    }

    public func chainOperations(operations: [BaseOperation],
                                completionBlock: GrandOperatorCompletionBlock?) {
        // Add dependencies
        var lastOp: NSOperation? = nil
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
                lastOp.completionBlock = nil
                for op in operations {
                    errors.appendContentsOf(op.errors)
                }
                // Only the first error will be reported
                if let block = completionBlock {
                    block(error: errors.first)
                }
            }
        }
    }

    public func shutdown() {
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
                completionBlock?(error: op.errors.first)
            }
        }
        op.start()
    }

    public func fetchFolders(connectInfo: ConnectInfo,
                             completionBlock: GrandOperatorCompletionBlock?) {
        let op = FetchFoldersOperation.init(
            connectInfo: connectInfo, coreDataUtil: coreDataUtil,
            connectionManager: connectionManager, onlyUpdateIfNecessary: false)
        kickOffConcurrentOperation(operation: op, completionBlock: completionBlock)
    }

    public func fetchEmailsAndDecryptConnectInfos(
        connectInfos: [ConnectInfo], folderName: String?,
        completionBlock: GrandOperatorCompletionBlock?) {
        var operations = [BaseOperation]()
        var fetchOperations = [BaseOperation]()

        for connectInfo in connectInfos {
            operations.append(CreateLocalSpecialFoldersOperation.init(
                coreDataUtil: coreDataUtil,
                accountEmail: connectInfo.email))
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
                GCD.onMain({
                    if let block = completionBlock {
                        block(error: error)
                    }
                })
        })
    }

    public func createSpecialLocalFolders(accountEmail: String,
                                          completionBlock: GrandOperatorCompletionBlock?) {
        let op = CreateLocalSpecialFoldersOperation.init(coreDataUtil: coreDataUtil,
                                                         accountEmail: accountEmail)
        kickOffConcurrentOperation(operation: op, completionBlock: completionBlock)
    }

    func handleVerificationCompletionFinished1(finished1: Bool, finished2: Bool,
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
            completionBlock?(error: error)
        }
    }

    public func verifyConnection(connectInfo: ConnectInfo,
                                 completionBlock: GrandOperatorCompletionBlock?) {
        let op1 = VerifyImapConnectionOperation.init(grandOperator: self, connectInfo: connectInfo)
        let op2 = VerifySmtpConnectionOperation.init(grandOperator: self, connectInfo: connectInfo)

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

    public func sendMail(message: IMessage, account: Account,
                         completionBlock: GrandOperatorCompletionBlock?) {
        let encryptionData = EncryptionData.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil,
            coreDataMessageID: (message as! Message).objectID, accountEmail: account.email)

        let opEncrypt = EncryptMailOperation.init(encryptionData: encryptionData)
        let opSend = SendMailOperation.init(encryptionData: encryptionData)
        let opSaveSent = SaveSentMessageOperation.init(encryptionData: encryptionData)

        opSaveSent.addDependency(opSend)
        opSend.addDependency(opEncrypt)

        opSaveSent.completionBlock = {
            var firstError: NSError?
            for op in [opEncrypt, opSend, opSaveSent] {
                if let err = op.errors.first {
                    firstError = err
                    break
                }
            }
            completionBlock?(error: firstError)
        }

        backgroundQueue.addOperation(opEncrypt)
        backgroundQueue.addOperation(opSend)
        backgroundQueue.addOperation(opSaveSent)
    }

    public func saveDraftMail(message: IMessage, account: IAccount,
                              completionBlock: GrandOperatorCompletionBlock?) {
        guard let folder = model.folderByType(.Drafts, email: account.email) else {
            completionBlock?(error: Constants.errorInvalidParameter(self.comp,
                errorMessage: "Did not find the drafts folder"))
            return
        }
        let opStore = AppendSingleMessageOperation.init(
            message: message, account: account, targetFolder: folder,
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
        opStore.completionBlock = {
            GCD.onMain() {
                completionBlock?(error: opStore.errors.first)
            }
        }
        backgroundQueue.addOperation(opStore)
    }

    public func syncFlagsToServerForFolder(folder: IFolder,
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
            blockOrig?()
            let firstError = operation?.errors.first
            completionBlock?(error: firstError)
        }
        if let op = operation {
            backgroundQueue.addOperation(op)
        }
    }
}