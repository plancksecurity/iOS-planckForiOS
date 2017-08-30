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
public class ConcurrentBaseOperation: BaseOperation {
    /**
     If you need to spawn child operations (that is, subtasks that should be waited upon),
     schedule them on this queue.
     */
    let backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    /** Do we observe the `operationCount` of `backgroundQueue`? */
    var operationCountObserverAdded = false

    /** Constant for observing the background queue */
    let operationCountKeyPath = "operationCount"

    /** Keypath for `OperationQueue.isCancelled` */
    let isCancelledKeyPath = "isCancelled"

    lazy var privateMOC: NSManagedObjectContext = Record.Context.background

    var myFinished: Bool = false

    public override var isExecuting: Bool {
        return !isFinished
    }

    public override var isAsynchronous: Bool {
        return true
    }

    public override var isFinished: Bool {
        return myFinished && backgroundQueue.operationCount == 0
    }

    deinit {
        if operationCountObserverAdded {
            backgroundQueue.removeObserver(self, forKeyPath: operationCountKeyPath)
        }
    }

    public override func start() {
        if !shouldRun() {
            return
        }
        Log.verbose(component: comp, content: "\(#function)")
        // Just call main directly, relying on it to schedule a task in the background.
        main()
    }

    /**
     If you scheduled operations on `backgroundQueue`, use this to 'wait' for them
     to finish and then signal `finished`.
     Although this method has 'wait' in the name, it certainly does not block.
     */
    func waitForBackgroundTasksToFinish() {
        Log.verbose(component: comp, content: "\(#function) \(backgroundQueue.operationCount)")
        if backgroundQueue.operationCount == 0 {
            markAsFinished()
        } else {
            operationCountObserverAdded = true
            backgroundQueue.addObserver(self, forKeyPath: operationCountKeyPath,
                                        options: [.initial, .new],
                                        context: nil)
            self.addObserver(self, forKeyPath: isCancelledKeyPath,
                             options: [.initial, .new],
                             context: nil)
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                                change: [NSKeyValueChangeKey : Any]?,
                                                context: UnsafeMutableRawPointer?) {
        guard let newValue = change?[NSKeyValueChangeKey.newKey] else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change,
                               context: context)
            return
        }
        if keyPath == operationCountKeyPath {
            let opCount = (newValue as? NSNumber)?.intValue
            Log.verbose(component: comp, content: "opCount \(String(describing: opCount))")
            if let c = opCount, c == 0 {
                markAsFinished()
            }
        } else if keyPath == isCancelledKeyPath {
            guard let cancelled = (newValue as? NSNumber)?.boolValue else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change,
                                   context: context)
                return
            }
            if cancelled {
                for op in backgroundQueue.operations {
                    op.cancel()
                }
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
        let isFinishedKeyPath = "isFinished"
        let isExecutingKeyPath = "isExecuting"
        Log.verbose(component: comp, content: #function)
        willChangeValue(forKey: isFinishedKeyPath)
        willChangeValue(forKey: isExecutingKeyPath)
        myFinished = true
        didChangeValue(forKey: isExecutingKeyPath)
        didChangeValue(forKey: isFinishedKeyPath)
    }

    public override func shouldRun() -> Bool {
        if !super.shouldRun() {
            markAsFinished()
            return false
        }
        return true
    }

    /**
     Indicates an error setting up the operation. For now, this is handled
     the same as any other error, but that might change.
     */
    func handleEntryError(_ error: Error, message: String? = nil) {
        handleError(error, message: message)
    }

    func handleError(_ error: Error, message: String? = nil) {
        addError(error)
        if let theMessage = message {
            Log.shared.error(component: comp, errorString: theMessage, error: error)
        } else {
            Log.shared.error(component: comp, error: error)
        }
        markAsFinished()
    }
}
