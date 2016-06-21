//
//  PEPUtil.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class PEPUtil {
    private static let homeUrl = NSURL(fileURLWithPath:
                                      NSProcessInfo.processInfo().environment["HOME"]!)
    private static let pEpManagementDbUrl =
                                         homeUrl.URLByAppendingPathComponent(".pEp_management.db")
    private static let systemDbUrl = homeUrl.URLByAppendingPathComponent("system.db")
    private static let gnupgUrl = homeUrl.URLByAppendingPathComponent(".gnupg")
    private static let gnupgSecringUrl = gnupgUrl.URLByAppendingPathComponent("secring.gpg")
    private static let gnupgPubringUrl = gnupgUrl.URLByAppendingPathComponent("pubring.gpg")
    
    // Provide filepath URLs as public dictionary.
    public static let pEpUrls: [String:NSURL] = [
                      "home": homeUrl,
                      "pEpManagementDb": pEpManagementDbUrl,
                      "systemDb": systemDbUrl,
                      "gnupg": gnupgUrl,
                      "gnupgSecring": gnupgSecringUrl,
                      "gnupgPubring": gnupgPubringUrl]
    
    // Delete pEp working data.
    public static func pEpClean() -> Bool {
        let pEpItemsToDelete: [String] = ["pEpManagementDb", "gnupg", "systemDb"]
        var error: NSError?
        
        for key in pEpItemsToDelete {
            let fileManager: NSFileManager = NSFileManager.defaultManager()
            let itemToDelete: NSURL = pEpUrls[key]!
            if itemToDelete.checkResourceIsReachableAndReturnError(&error) {
                do {
                    try fileManager.removeItemAtURL(itemToDelete)
                }
                catch {
                    return false
                }
            }
        }
        return true
    }

    public static func identityFromAccount(account: Account,
                                           isMyself: Bool = true) -> NSMutableDictionary {
        let dict = NSMutableDictionary.init(capacity: 5)
        dict[kPepUsername] = account.nameOfTheUser
        dict[kPepAddress] = account.email
        return dict
    }

    /**
     Kicks off myself in the background, optionally notifies via block of termination/success.
     */
    public static func myselfFromAccount(account: Account,
                                         block: ((identity: NSDictionary) -> Void)? = nil) {
        let op = PEPMyselfOperation.init(account: account)
        op.completionBlock = {
            if let bl = block {
                bl(identity: op.identity)
            }
        }
        let queue = NSOperationQueue.init()
        queue.addOperation(op)
    }
}