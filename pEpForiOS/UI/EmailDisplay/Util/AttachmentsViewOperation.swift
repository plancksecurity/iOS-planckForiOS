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
    let cellWidth: CGFloat?

    /**
     The resulting attachments view will appear here.
     */
    var attachmentViews = [UIView]()

    /**
     The number of attachments.
     */
    var attachmentsCount = 0

    init(mimeTypes: MimeTypeUtil?, message: Message, cellWidth: CGFloat?) {
        self.mimeTypes = mimeTypes
        self.message = message
        self.cellWidth = cellWidth

        super.init()

        attachmentsCount = eligibleAttachments().count
    }

    func eligibleAttachments() -> [Attachment] {
        return message.attachments.filter() { att in
            return (mimeTypes?.isImage(mimeType: att.mimeType) ?? false) && att.data != nil
        }
    }

    override func main() {
        let attachments = eligibleAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                view.contentMode = .scaleAspectFill
                attachmentViews.append(view)
            }
        }
    }
}
