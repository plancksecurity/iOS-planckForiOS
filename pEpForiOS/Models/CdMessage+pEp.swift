
//
//  CdMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdMessage {
    /**
     Updates all properties from the given `PEPMail`.
     Used after a mail has been decrypted.
     TODO: Take care of optional fields (`kPepOptFields`)!
     */
    public func update(pEpMail: PEPMail, pepColorRating: PEP_rating? = nil) {
        if let color = pepColorRating {
            pEpRating = Int16(color.rawValue)
        }

        bodyFetched = true

        shortMessage = pEpMail[kPepShortMessage] as? String
        longMessage = pEpMail[kPepLongMessage] as? String
        longMessageFormatted = pEpMail[kPepLongMessageFormatted] as? String

        // Remove all existing attachments. These should cascade.

        var attachments = [CdAttachment]()
        if let attachmentDicts = pEpMail[kPepAttachments] as? NSArray {
            for atDict in attachmentDicts {
                guard let at = atDict as? NSDictionary else {
                    continue
                }
                guard let data = at[kPepMimeData] as? Data else {
                    continue
                }
                let attach = CdAttachment.create()
                attach.data = data as NSData
                attach.size = Int64(data.count)
                if let mt = at[kPepMimeType] as? String {
                    attach.mimeType = mt
                }
                if let fn = at[kPepMimeFilename] as? String {
                    attach.fileName = fn
                }

                attachments.append(attach)
            }
        }
        self.attachments = NSOrderedSet(array: attachments)

        to = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMail[kPepTo] as? [PEPContact]))
        cc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMail[kPepCC] as? [PEPContact]))
        bcc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMail[kPepBCC] as? [PEPContact]))
    }
}
