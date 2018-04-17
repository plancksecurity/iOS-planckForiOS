//
//  CdAttachment+Pantomime.swift
//  pEp
//
//  Created by Andreas Buff on 17.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// CONTENT DISPOSITION

extension CdAttachment {
    static func contentDispositionRawValue(from
        pantomimeContentDisposition: PantomimeContentDisposition) -> Int16 {
        switch pantomimeContentDisposition {
        case PantomimeAttachmentDisposition:
            return Attachment.ContentDispositionType.attachment.rawValue
        case PantomimeInlineDisposition:
            return Attachment.ContentDispositionType.inline.rawValue
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled case")
            return Attachment.ContentDispositionType.attachment.rawValue
        }
    }
}
