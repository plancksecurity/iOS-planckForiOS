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
    var attachmentViewContainers = [AttachmentViewContainer]()

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
        let dic = UIDocumentInteractionController()
        let attachments = message.viewableAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                attachmentViewContainers.append(AttachmentViewContainer(view: view,
                                                                        attachment: att))
            } else {
                dic.name = att.fileName
                let view = AttachmentSummaryView(attachment: att, iconImage: dic.icons.first)
                attachmentViewContainers.append(AttachmentViewContainer(view: view, attachment: att))
            }
        }
    }
}
