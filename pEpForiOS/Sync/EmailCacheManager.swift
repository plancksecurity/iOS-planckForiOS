//
//  CacheManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol EmailCache: CWCache, CWIMAPCache {
}

/**
 This is the interface the IMAP implementation (and possibly others) uses to store mails.
 */
@objc public class EmailCacheManager: NSObject, EmailCache {

    public func invalidate() {
    }

    public func synchronize() -> Bool {
        return true
    }

    public func count() -> UInt {
        return 0
    }

    public func removeMessageWithUID(theUID: UInt) {
    }

    public func UIDValidity() -> UInt {
        return 0
    }

    public func setUIDValidity(theUIDValidity: UInt) {
    }

    public func messageWithUID(theUID: UInt) -> CWIMAPMessage! {
        return nil
    }

    func dumpMessage(msg: CWMessage) {
        print("CWMessage: contentType(\(msg.contentType()))",
              " isInitialized(\(msg.isInitialized()))\n",
              " content(\(msg.content()))")
    }

    public func writeRecord(theRecord: CWCacheRecord!, message: CWIMAPMessage!) {
        if let folder = message.folder() {
            print("write UID(\(message.UID())) folder(\(folder.name()))")
        }
        dumpMessage(message)
    }

}