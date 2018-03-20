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
    enum AttachmentContainer {
        case imageAttachment(Attachment, UIImage)
        case docAttachment(Attachment)
    }

    let mimeTypes: MimeTypeUtil?
    let message: Message

    /**
     The resulting attachments view will appear here.
     */
    var attachmentContainers = [AttachmentContainer]()

    /**
     The number of attachments.
     */
    var attachmentsCount = 0

    init(mimeTypes: MimeTypeUtil?, message: Message) {
        self.mimeTypes = mimeTypes
        self.message = message

        super.init()

        attachmentsCount = message.viewableAttachments().count
    }

    override func main() {
        let attachments = message.viewableAttachments()
        for att in attachments {
            if att.isInlined {
                // Ignore attachments that are already shown inlined in the message body.
                continue
            }
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                attachmentContainers.append(.imageAttachment(att, img))
            } else {
                attachmentContainers.append(.docAttachment(att))
            }
        }
    }
}
