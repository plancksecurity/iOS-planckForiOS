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
     Asychronously prefetches emails (headers, like subject, to, etc.) for the given `ConnectInfo`
     and the given folder and stores them into the persistent store.

     - parameter connectInfo: Denotes the server and other connection parameters
     - parameter completionBlock: Will be called on completion of the operation, with
     a non-nil error object if there was an error during execution.
     */
    func prefetchEmails(connectInfo: ConnectInfo, folder: String?,
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
    func saveDraftMail(email: IMessage, completionBlock: GrandOperatorCompletionBlock?)

    /**
     A model suitable for accessing core data from this thread, cached in thread-local
     storage.
     - Returns: The model suitable for the caller, depending on whether this is called on the
     main thread or not.
     */
    func operationModel() -> IModel

    /**
     - Returns: A model built on a private context (`.PrivateQueueConcurrencyType`)
     */
    func backgroundModel() -> IModel
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

    public func prefetchEmails(connectInfo: ConnectInfo, folder: String?,
                        completionBlock: GrandOperatorCompletionBlock?) {
        let op = PrefetchEmailsOperation.init(grandOperator: self, connectInfo: connectInfo,
                                              folder: folder)
        kickOffConcurrentOperation(operation: op, completionBlock: completionBlock)
    }

    public func fetchFolders(connectInfo: ConnectInfo,
                             completionBlock: GrandOperatorCompletionBlock?) {
        let op = FetchFoldersOperation.init(
            grandOperator: self, connectInfo: connectInfo, onlyUpdateIfNecessary: false)
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
                grandOperator: self, connectInfo: connectInfo, onlyUpdateIfNecessary: true))

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
        opSend.addDependency(opEncrypt)
        opSend.completionBlock = {
            Log.errorComponent(self.comp, error: Constants.errorNotImplemented(self.comp)) // test
            var firstError = opEncrypt.errors.first
            if firstError == nil {
                firstError = opSend.errors.first
            }
            completionBlock?(error: firstError)
        }
        backgroundQueue.addOperation(opSend)
        backgroundQueue.addOperation(opEncrypt)
    }

    public func saveDraftMail(message: IMessage, completionBlock: GrandOperatorCompletionBlock?) {
        completionBlock?(error: Constants.errorNotImplemented(comp))
    }

    /**
     Creates a new background model, confined to the current thread/queue
     */
    private func createBackgroundModel() -> IModel {
        return Model.init(context: coreDataUtil.confinedManagedObjectContext())
    }

    public func operationModel() -> IModel {
        if NSThread.isMainThread() {
            return model
        }
        let threadDictionary = NSThread.currentThread().threadDictionary
        if let model = threadDictionary[GrandOperator.kOperationModel] {
            return model as! IModel
        }
        let resultModel = createBackgroundModel()
        threadDictionary.setValue(resultModel as? AnyObject, forKey: GrandOperator.kOperationModel)
        return resultModel
    }

    public func backgroundModel() -> IModel {
        return Model.init(context: coreDataUtil.privateContext())
    }
}