//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

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
                        completionBlock: ((error: NSError?) -> Void)?)

    /**
     Used by background operations to set an error.
     
     - parameter operation: The operation the error occurred
     - parameter error: The error that occurred
     */
    func setErrorForOperation(operation: NSOperation, error: NSError)
}

public class GrandOperator: IGrandOperator {

    public let connectionManager: ConnectionManager
    public let coreDataUtil: ICoreDataUtil

    public var errors: [NSOperation:NSError] = [:]

    let prefetchQueue = NSOperationQueue.init()

    init(connectionManager: ConnectionManager, coreDataUtil: CoreDataUtil) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    public func prefetchEmails(connectInfo: ConnectInfo, folder: String?,
                        completionBlock: ((error: NSError?) -> Void)?) {
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

    public func setErrorForOperation(operation: NSOperation, error: NSError) {
        GCD.onMain({
            self.errors[operation] = error
        })
    }
}