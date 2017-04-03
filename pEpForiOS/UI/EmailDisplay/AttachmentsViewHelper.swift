//
//  AttachmentsViewHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class AttachmentsViewHelper {
    let mimeTypes = MimeTypeUtil()
    var message: Message? {
        didSet {
            if let m = message {
                updateQuickMetaData(message: m)
            }
        }
    }
    var imageAttachments = [Attachment]()
    var hasAttachments: Bool {
        return !imageAttachments.isEmpty
    }

    func updateQuickMetaData(message: Message) {
        imageAttachments.removeAll()

        for att in message.attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false) && att.data != nil {
                imageAttachments.append(att)
            }
        }
    }
}
