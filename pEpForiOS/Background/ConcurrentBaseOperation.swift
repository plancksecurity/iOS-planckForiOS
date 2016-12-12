//
//  ConcurrentBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 This is the base for concurrent `NSOperation`s, that is operations
 that handle asynchronicity themselves, and are typically not finished when `main()` ends.
 Instead, they spawn their own threads or use other forms of asynchronicity.
 */
open class ConcurrentBaseOperation: BaseOperation {
    /**
     If you need to spawn child operations (that is, subtasks that should be waited upon),
     schedule them on this queue.
     */
    let backgroundQueue = OperationQueue.init()

    lazy var privateMOC: NSManagedObjectContext = Record.Context.background

    var myFinished: Bool = false

    open override var isExecuting: Bool {
        return !isFinished
    }

    open override var isAsynchronous: Bool {
        return true
    }

    open override var isFinished: Bool {
        return myFinished && backgroundQueue.operationCount == 0
    }

    open override func start() {
        // Just call main directly, relying on it to schedule a task in the background.
        main()
    }

    /**
     If you scheduled operations on `backgroundQueue`, use this to 'wait' for them
     to finish and then signal `finished`.
     Although this method has 'wait' in the name, it certainly does not block.
     */
    func waitForFinished() {
        if backgroundQueue.operationCount == 0 {
            markAsFinished()
        } else {
            backgroundQueue.addObserver(self, forKeyPath: "operationCount",
                                        options: [.initial, .new],
                                        context: nil)
            self.addObserver(self, forKeyPath: "isCancelled",
                             options: [.initial, .new],
                             context: nil)
        }
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                                change: [NSKeyValueChangeKey : Any]?,
                                                context: UnsafeMutableRawPointer?) {
        if keyPath == "operationCount" {
            if let newValue = change?[NSKeyValueChangeKey.newKey] {
                let opCount = (newValue as? NSNumber)?.intValue
                if let c = opCount, c == 0 {
                    markAsFinished()
                }
            }
        } else if keyPath == "isCancelled" {
            for op in backgroundQueue.operations {
                op.cancel()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change,
                                         context: context)
        }
    }

    /**
     Use this if you didn't schedule any operations on `backgroundQueue` and want
     to signal the end of this operation.
     */
    func markAsFinished() {
        willChangeValue(forKey: "isFinished")
        willChangeValue(forKey: "isExecuting")
        myFinished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }

    func checkImapSync(sync: ImapSync?) -> Bool {
        if sync == nil {
            addError(Constants.errorImapInvalidConnection(component: comp))
            markAsFinished()
            return false
        }
        return true
    }
}
