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

    let spacing: CGFloat = 10
    let margin: CGFloat = 10

    /**
     The resulting attachments view will appear here.
     */
    var resultView: UIView?
    var attachmentsCount: Int = 0

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

    func guessCellWidth() -> CGFloat {
        return cellWidth ?? UIScreen.main.bounds.width
    }

    override func main() {
        var attachmentViews = [UIView]()

        let attachments = eligibleAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                view.contentMode = .scaleAspectFill
                attachmentViews.append(view)
            }
        }

        // The frame needed to place all attachment images
        let maxWidth = guessCellWidth() - 2 * margin
        let theFrame = CGRect(origin: CGPoint.zero,
                              size: CGSize(width: maxWidth, height: 0.0))

        let view = ImageView(frame: theFrame)
        view.backgroundColor = .blue
        view.attachedViews = attachmentViews
        view.spacing = spacing
        view.frame = theFrame
        view.layoutIfNeeded()

        resultView = view
    }
}
