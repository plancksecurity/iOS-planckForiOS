//
//  PEPUtils.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PantomimeFramework
import PEPObjCAdapterFramework

//!!!: Clean up! 1) Loads of topics mixed here. 2) Loads of public methods that expose CoreData.

public class PEPUtils {
    /// Content type for MIME multipart/alternative.
    public static let kMimeTypeMultipartAlternative = "multipart/alternative"

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
