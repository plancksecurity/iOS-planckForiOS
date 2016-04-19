//
//  PersistentEmailCache.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class PersistentEmailCache: NSObject {
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    let grandOperator: GrandOperator

    init(grandOperator: GrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.grandOperator = grandOperator
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
    }

    func saveMessage(message: CWMessage) {
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: message as! CWIMAPMessage)
        backgroundQueue.addOperation(op)
    }
}

extension PersistentEmailCache: EmailCache {
    func invalidate() {
    }

    func synchronize() -> Bool {
        return true
    }

    func count() -> UInt {
        return 0
    }

    func removeMessageWithUID(theUID: UInt) {
    }

    func UIDValidity() -> UInt {
        return 0
    }

    func setUIDValidity(theUIDValidity: UInt) {
    }

    func messageWithUID(theUID: UInt) -> CWIMAPMessage! {
        return nil
    }

    func writeRecord(theRecord: CWCacheRecord!, message: CWIMAPMessage!) {
        saveMessage(message)
    }
}