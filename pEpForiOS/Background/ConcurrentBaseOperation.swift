//
//  ConcurrentBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

public class ConcurrentBaseOperation: BaseOperation {
    let backgroundQueue = NSOperationQueue.init()
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