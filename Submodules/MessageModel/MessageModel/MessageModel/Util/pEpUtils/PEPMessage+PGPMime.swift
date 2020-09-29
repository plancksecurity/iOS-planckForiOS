//
//  PEPMessage+PGPMime.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension PEPMessage {
    /// Checks whether this PEPMessage is probably PGP/MIME encrypted.
    func isProbablyPGPMime() -> Bool {
        guard let attachments = attachments else {
            return false
        }

        var foundAttachmentPGPEncrypted = false
        for attachment in attachments {
            guard let filename = attachment.mimeType else {
                continue
            }
            if filename.lowercased() == MimeTypeUtils.MimesType.pgpEncrypted.rawValue {
                foundAttachmentPGPEncrypted = true
                break
            }
        }
        return foundAttachmentPGPEncrypted
    }
}
