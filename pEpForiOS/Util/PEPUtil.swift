//
//  PEPUtil.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class PEPUtil {
    /**
     Mime type for the "Version" attachment of PGP/MIME.
     */
    public static let mimeTypePGPEncrypted = "application/pgp-encrypted"

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
        let dict: NSMutableDictionary = [:]
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

    /**
     Converts a core data contact to a pEp contact.
     - Parameter contact: The core data contact object.
     - Returns: An `NSMutableDictionary` contact for pEp.
     */
    public static func pepContact(contact: IContact) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]
        if let name = contact.name {
            dict[kPepUsername] = name
        }
        dict[kPepAddress] = contact.email
        if let userID = contact.userID {
            dict[kPepUserID] = userID
        }
        return dict
    }

    /**
     Converts a core data attachment to a pEp attachment.
     - Parameter contact: The core data attachment object.
     - Returns: An `NSMutableDictionary` attachment for pEp.
     */
    public static func pepAttachment(attachment: IAttachment) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]

        if let filename = attachment.filename {
            dict[kPepMimeFilename] = filename
        }
        if let contentType = attachment.contentType {
            dict[kPepMimeType] = contentType
        }
        dict[kPepMimeData] = attachment.content.data

        return dict
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: An object (`NSMutableDictionary`) suitable for processing with pEp.
     */
    public static func pepMail(message: IMessage, outgoing: Bool = true) -> PEPMail {
        let dict: NSMutableDictionary = [:]

        if let subject = message.subject {
            dict[kPepShortMessage] = subject
        }

        dict[kPepTo] = message.to.map() { pepContact($0 as! Contact) }
        dict[kPepCC] = message.cc.map() { pepContact($0 as! Contact) }
        dict[kPepBCC] = message.bcc.map() { pepContact($0 as! Contact) }

        if let longMessage = message.longMessage {
            dict[kPepLongMessage] = longMessage
        }
        if let longMessageFormatted = message.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted
        }
        if let from = message.from {
            dict[kPepFrom]  = self.pepContact(from)
        }
        dict[kPepOutgoing] = outgoing

        dict[kPepAttachments] = message.attachments.map() { pepAttachment($0 as! IAttachment) }

        return dict as PEPMail
    }

    public static func insertPepContact(
        pepContact: PEPContact, intoModel: IModel) -> IContact {
        let contact = intoModel.insertOrUpdateContactEmail(
            pepContact[kPepAddress] as! String,
            name: pepContact[kPepUsername] as? String)
        return contact
    }

    /**
     For a PEPMail, checks whether it is PGP/MIME encrypted.
     */
    public static func isProbablyPGPMime(message: PEPMail) -> Bool {
        var foundAttachmentPGPEncrypted = false
        let attachments = message[kPepAttachments] as! NSArray
        for atch in attachments {
            if let filename = atch[kPepMimeType] as? String {
                if filename.lowercaseString == mimeTypePGPEncrypted {
                    foundAttachmentPGPEncrypted = true
                    break
                }
            }
        }
        return foundAttachmentPGPEncrypted
    }
}