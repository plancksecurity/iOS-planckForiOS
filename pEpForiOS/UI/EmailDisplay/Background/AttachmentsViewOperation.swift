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
                // Ignore attachments that are already shown inline in the message body.
                // Try to verify this by checking if their CID (if any) is mentioned there.
                // So attachments labeled as inline _are_ shown if
                //  * they don't have a CID
                //  * their CID doesn't occur in the HTML body
                var cidContained = false
                if let theCid = att.fileName?.extractCid() {
                    cidContained = message.longMessageFormatted?.contains(
                        find: theCid) ?? false
                }
                if cidContained {
                    // seems like this inline attachment is really inline, don't show it
                    continue
                }
            }

            let isImage: Bool
            if let mimeType = att.mimeType {
                isImage = mimeTypes?.isImage(mimeType: mimeType) ?? false
            } else {
                isImage = false
            }
            if (isImage),
                let imgData = att.data,
                let img = UIImage.image(gifData: imgData) ?? UIImage(data: imgData) {
                attachmentContainers.append(.imageAttachment(att, img))
            } else {
                attachmentContainers.append(.docAttachment(att))
            }
        }
    }
}
