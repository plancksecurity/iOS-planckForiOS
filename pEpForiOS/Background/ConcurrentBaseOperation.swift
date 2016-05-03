//
//  ConcurrentBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Base class for concurrent operations (operations that are not contained in a background queue
 and handle their own concurrency), that operate a background operation for additional tasks.
 */
public class ConcurrentBaseOperation: BaseOperation {
    let backgroundQueue: NSOperationQueue

    public override init(grandOperator: IGrandOperator) {
        backgroundQueue = NSOperationQueue.init()
        super.init(grandOperator: grandOperator)
    }

    public override var executing: Bool {
        return !finished
    }

    public override var asynchronous: Bool {
        return true
    }

    public override var finished: Bool {
        return myFinished && backgroundQueue.operationCount == 0
    }

    override public static func automaticallyNotifiesObserversForKey(keyPath: String) -> Bool {
        var automatic: Bool = false
        if keyPath == "isFinished" {
            automatic = false
        } else {
            automatic = super.automaticallyNotifiesObserversForKey(keyPath)
        }
        return automatic
    }

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

    func markAsFinished() {
        willChangeValueForKey("isFinished")
        myFinished = true
        didChangeValueForKey("isFinished")
    }
}