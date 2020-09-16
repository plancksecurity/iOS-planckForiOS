//
//  PEPUtils.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import PantomimeFramework
import PEPObjCAdapterFramework
import CoreData

//!!!: Clean up! 1) Loads of topics mixed here. 2) Loads of public methods that expose CoreData.

public class PEPUtils {

    /// Content type for MIME multipart/alternative.
    public static let kMimeTypeMultipartAlternative = "multipart/alternative"

    ///Delete pEp working data.
    //!!!: MUST go to test utils
    public static func pEpClean() -> Bool {
        PEPSession.cleanup()

        let homeString = PEPObjCAdapter.perUserDirectoryString()
        let homeUrl = URL(fileURLWithPath: homeString, isDirectory: true)

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: homeString) {
            // Might happen if engine was never used.
            return true
        }

        guard let enumerator = fileManager.enumerator(atPath: homeString) else {
            // Since we already know the directory exists, not getting back
            // an enumerator is an error.
            return false
        }

        var success = true
        for path in enumerator {
            if let pathString = path as? String {
                let fileUrl = URL(fileURLWithPath: pathString, relativeTo: homeUrl)
                do {
                    try fileManager.removeItem(at: fileUrl)
                } catch {
                    success = false
                }
            } else {
                success = false
            }
        }

        return success
    }

    public static func pEpIdentity(for cdAccount: CdAccount) -> PEPIdentity {
        if let id = cdAccount.identity {
            return id.pEpIdentity()
        } else {
            Log.shared.errorAndCrash(
                "account without identity: %@", cdAccount)
            return PEPIdentity(address: "none")
        }
    }

    public static func pEpOptional(identity: Identity?) -> PEPIdentity? {
        guard let id = identity else {
            return nil
        }
        return id.pEpIdentity()
    }

    //!!!: used only in test. RM!
    /**
     Converts a `Attachment` into a PEPAttachment.
     */
    public static func pEpAttachment(attachment: Attachment) -> PEPAttachment {
        return attachment.cdObject.pEpAttachment
    }

    /**
     Converts a typical core data set of CdIdentities into pEp identities.
     */
    public static func pEpIdentities(cdIdentitiesSet: NSOrderedSet?) -> [PEPIdentity]? {
        guard let cdIdentities = cdIdentitiesSet?.array as? [CdIdentity] else {
            return nil
        }
        return cdIdentities.map {
            return $0.pEpIdentity()
        }
    }

    /// For a PEPMessage, checks whether it is probably PGP/MIME encrypted.
    public static func isProbablyPGPMime(pEpMessage: PEPMessage) -> Bool { //!!!: should be extension on PEPMessage
        guard let attachments = pEpMessage.attachments else {
            return false
        }

        var foundAttachmentPGPEncrypted = false
        for attachment in attachments {
            guard let filename = attachment.mimeType else {
                continue
            }
            if filename.lowercased() == ContentTypeUtils.ContentType.pgpEncrypted {
                foundAttachmentPGPEncrypted = true
                break
            }
        }
        return foundAttachmentPGPEncrypted
    }

    /// For a CdMessage, checks whether it is probably PGP/MIME encrypted.
    public static func isProbablyPGPMime(cdMessage: CdMessage) -> Bool { //!!!: should be extension on CdMessage
        return isProbablyPGPMime(pEpMessage: cdMessage.pEpMessage())
    }

    /// Converts a pEp identity dict to a pantomime address.
    public static func pantomime(pEpIdentity: PEPIdentity) -> CWInternetAddress {
        return CWInternetAddress(personal: pEpIdentity.userName, address: pEpIdentity.address)  //!!!: should be extension on PEPIdentity
    }

    static func pEpRating(cdIdentity: CdIdentity,
                          context: NSManagedObjectContext = Stack.shared.mainContext,
                          completion: @escaping (PEPRating)->Void) {
        var pepIdentity: PEPIdentity? = nil
        if context == Stack.shared.mainContext {
            pepIdentity = cdIdentity.pEpIdentity()
        } else {
            context.performAndWait {
                pepIdentity = cdIdentity.pEpIdentity()
            }
        }
        guard let savePepIdentity = pepIdentity else {
            Log.shared.errorAndCrash("No savePepIdentity")
            completion(.undefined)
            return
        }

        PEPAsyncSession().rating(for: savePepIdentity, errorCallback: { (error) in
            Log.shared.errorAndCrash(error: error)
            completion(.undefined)
        }) { (rating) in
            completion(rating)
        }
    }

    static func pEpColor(cdIdentity: CdIdentity,
                         context: NSManagedObjectContext = Stack.shared.mainContext,
                         completion: @escaping (PEPColor)->Void) {
        pEpRating(cdIdentity: cdIdentity, context: context) { (rating) in
            completion(pEpColor(pEpRating: rating))
        }
    }

    public static func pEpColor(pEpRating: PEPRating?) -> PEPColor {
        if let rating = pEpRating {
            return PEPSession().color(from: rating)
        } else {
            return PEPColor.noColor
        }
    }
}
