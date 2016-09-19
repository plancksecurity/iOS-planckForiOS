//
//  ConcurrentBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

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
    let backgroundQueue = NSOperationQueue.init()

    let coreDataUtil: ICoreDataUtil

    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    var myFinished: Bool = false

    public override var executing: Bool {
        return !finished
    }

    public override var asynchronous: Bool {
        return true
    }

    public override var finished: Bool {
        return myFinished && backgroundQueue.operationCount == 0
    }

    public init(coreDataUtil: ICoreDataUtil) {
        self.coreDataUtil = coreDataUtil
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
                                        options: [.Initial, .New],
                                        context: nil)
        }
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                                                change: [String : AnyObject]?,
                                                context: UnsafeMutablePointer<Void>) {
        if keyPath == "operationCount" {
            if let newValue = change?[NSKeyValueChangeNewKey] {
                if newValue.intValue == 0 {
                    markAsFinished()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change,
                                         context: context)
        }
    }

    /**
     Use this if you didn't schedule any operations on `backgroundQueue` and want
     to signal the end of this operation.
     */
    func markAsFinished() {
        willChangeValueForKey("isFinished")
        myFinished = true
        didChangeValueForKey("isFinished")
    }
}