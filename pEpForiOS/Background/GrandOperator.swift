//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public typealias GrandOperatorCompletionBlock = (error: NSError?) -> Void

public protocol IGrandOperator {
    var coreDataUtil: ICoreDataUtil { get }

    var connectionManager: ConnectionManager { get }

    /**
     The main model (for use on the main thread)
     */
    var model: IModel { get }

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
     Asynchronously verifies the given connection. Tests for IMAP and SMTP. The test is considered
     a success when authentication was successful.
     */
    func verifyConnection(connectInfo: ConnectInfo, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Used by background operations to set an error.
     
     - parameter operation: The operation the error occurred
     - parameter error: The error that occurred
     */
    func setErrorForOperation(operation: NSOperation, error: NSError)

    /**
     - returns: The list of all errors
     */
    func allErrors() -> [NSError]

    /**
     Creates a new background model, confined to the current thread/queue
     */
    func backgroundModel() -> IModel
}

public class GrandOperator: IGrandOperator {
    let comp = "GrandOperator"

    public let connectionManager: ConnectionManager
    public let coreDataUtil: ICoreDataUtil

    private var errors: [NSOperation:NSError] = [:]

    private let prefetchQueue = NSOperationQueue.init()
    private let verifyConnectionQueue = NSOperationQueue.init()

    public lazy var model: IModel = {
        return self.createModel()
    }()

    public init(connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    public func prefetchEmails(connectInfo: ConnectInfo, folder: String?,
                        completionBlock: GrandOperatorCompletionBlock?) {
        let op = PrefetchEmailsOperation.init(grandOperator: self, connectInfo: connectInfo,
                                              folder: folder)
        if let block = completionBlock {
            op.completionBlock = { [unowned self] in
                let error = self.errors[op]
                block(error: error)
                self.errors.removeValueForKey(op)
            }
        }
        op.start()
    }

    func handleVerificationCompletion(finished1: Bool, finished2: Bool,
                                      op1: NSOperation, op2: NSOperation,
                                      completionBlock: GrandOperatorCompletionBlock?) {
        GCD.onMain({ // serialize
            if finished1 && finished2 {
                var error: NSError? = nil
                if let err = self.errors[op1] {
                    error = err
                } else if let err = self.errors[op2] {
                    error = err
                }
                completionBlock?(error: error)
            }
        })
    }

    public func verifyConnection(connectInfo: ConnectInfo,
                                 completionBlock: GrandOperatorCompletionBlock?) {
        var finished1 = false
        var finished2 = false

        let op1 = VerifyImapConnectionOperation.init(grandOperator: self, connectInfo: connectInfo)
        let op2 = VerifySmtpConnectionOperation.init(grandOperator: self, connectInfo: connectInfo)

        let completion1 = {
            finished1 = true
            self.handleVerificationCompletion(finished1, finished2: finished2,
                                              op1: op1, op2: op2,
                                              completionBlock: completionBlock)
        }
        let completion2 = {
            finished2 = true
            self.handleVerificationCompletion(finished1, finished2: finished2,
                                              op1: op1, op2: op2,
                                              completionBlock: completionBlock)
        }

        op1.completionBlock = completion1
        op2.completionBlock = completion2

        verifyConnectionQueue.addOperation(op1)
        verifyConnectionQueue.addOperation(op2)
    }

    public func setErrorForOperation(operation: NSOperation, error: NSError) {
        GCD.onMain({
            self.errors[operation] = error
        })
    }

    public func allErrors() -> [NSError] {
        var errors: [NSError] = []
        for (_, err) in self.errors {
            errors.append(err)
        }
        return errors
    }

    public func backgroundModel() -> IModel {
        return Model.init(context: coreDataUtil.confinedManagedObjectContext())
    }

    func createModel() -> IModel {
        return Model.init(context: coreDataUtil.managedObjectContext)
    }
}