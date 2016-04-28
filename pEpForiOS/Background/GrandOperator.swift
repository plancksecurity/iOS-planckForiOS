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

    var errors: [NSOperation:NSError] { get }

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
     Verifies the given connection. Tests for IMAP and SMTP.
     */
    func verifyConnection(connectInfo: ConnectInfo, completionBlock: GrandOperatorCompletionBlock?)

    /**
     Used by background operations to set an error.
     
     - parameter operation: The operation the error occurred
     - parameter error: The error that occurred
     */
    func setErrorForOperation(operation: NSOperation, error: NSError)
}

public class GrandOperator: IGrandOperator {
    let comp = "GrandOperator"

    public let connectionManager: ConnectionManager
    public let coreDataUtil: ICoreDataUtil

    public var errors: [NSOperation:NSError] = [:]

    let prefetchQueue = NSOperationQueue.init()

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
        let op2 = VerifyImapConnectionOperation.init(grandOperator: self, connectInfo: connectInfo)

        let completion1 = {
            finished1 = true
            self.handleVerificationCompletion(finished1, finished2: finished2,
                                              op1: op1, op2: op1,
                                              completionBlock: completionBlock)
        }
        let completion2 = {
            finished2 = true
            self.handleVerificationCompletion(finished1, finished2: finished2,
                                              op1: op1, op2: op1,
                                              completionBlock: completionBlock)
        }

        op1.completionBlock = completion1
        op2.completionBlock = completion2

        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.addOperation(op1)
        queue.addOperation(op2)
    }

    public func setErrorForOperation(operation: NSOperation, error: NSError) {
        GCD.onMain({
            self.errors[operation] = error
        })
    }
}