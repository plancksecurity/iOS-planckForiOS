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
    var resultView: UIView?
    var attachmentsCount: Int = 0

    init(mimeTypes: MimeTypeUtil?, message: Message) {
        self.mimeTypes = mimeTypes
        self.message = message

        super.init()

        attachmentsCount = eligibleAttachments().count
    }

    func eligibleAttachments() -> [Attachment] {
        return message.attachments.filter() { att in
            return (mimeTypes?.isImage(mimeType: att.mimeType) ?? false) && att.data != nil
        }
    }

    override func main() {
        var attachmentViews = [UIView]()
        var estimatedHeight: CGFloat = 0.0
        var estimatedWidth: CGFloat = 0.0

        let attachments = eligibleAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                view.contentMode = .scaleAspectFill
                estimatedHeight += view.intrinsicContentSize.height
                if view.intrinsicContentSize.width > estimatedWidth {
                    estimatedWidth = view.intrinsicContentSize.width
                }
                attachmentViews.append(view)
            }
        }
        let spacing: CGFloat = 10.0
        estimatedHeight += CGFloat(attachments.count) * spacing

        let stackedView = UIStackView(arrangedSubviews: attachmentViews)
        stackedView.axis = .vertical
        stackedView.distribution = .equalCentering
        stackedView.alignment = .center
        stackedView.spacing = spacing

        stackedView.frame = CGRect(origin: CGPoint(x: 0, y: 0),
                                   size: CGSize(width: estimatedWidth, height: estimatedHeight))

        resultView = stackedView
    }
}
