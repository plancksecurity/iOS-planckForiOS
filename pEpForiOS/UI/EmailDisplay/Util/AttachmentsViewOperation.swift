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

        let attachments = eligibleAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                view.contentMode = .scaleAspectFill
                attachmentViews.append(view)
            }
        }

        let stackedView = UIStackView(arrangedSubviews: attachmentViews)
        stackedView.axis = .vertical
        stackedView.distribution = .equalCentering
        stackedView.alignment = .center
        stackedView.spacing = 10.0

        stackedView.frame = CGRect.zero

        resultView = stackedView
    }
}
