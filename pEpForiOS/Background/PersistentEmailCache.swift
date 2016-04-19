//
//  PersistentEmailCache.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class PersistentEmailCache: NSObject, EmailCache {

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

    func dumpMessage(msg: CWMessage) {
        print("CWMessage: contentType(\(msg.contentType()))",
              " isInitialized(\(msg.isInitialized()))\n",
              " content(\(msg.content()))")
    }

    func writeRecord(theRecord: CWCacheRecord!, message: CWIMAPMessage!) {
        if let folder = message.folder() {
            print("write UID(\(message.UID())) folder(\(folder.name()))")
        }
        dumpMessage(message)
    }
}