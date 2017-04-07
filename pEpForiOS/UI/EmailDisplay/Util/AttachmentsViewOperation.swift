//
//  AttachmentsViewOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class AttachmentsViewOperation: Operation {
    let mimeTypes: MimeTypeUtil?
    let message: Message

    /**
     The resulting attachments view will appear here.
     */
    var attachmentViews = [UIView]()

    /**
     The number of attachments.
     */
    var attachmentsCount = 0

    init(mimeTypes: MimeTypeUtil?, message: Message) {
        self.mimeTypes = mimeTypes
        self.message = message

        super.init()

        attachmentsCount = eligibleAttachments().count
    }

    func eligibleAttachments() -> [Attachment] {
        return message.attachments.filter() { att in
            return att.data != nil && att.mimeType.lowercased() != "application/pgp-keys"
        }
    }

    override func main() {
        let attachments = eligibleAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                attachmentViews.append(view)
            } else {
                print("non-image attachment: \(att)")
            }
        }
    }
}
