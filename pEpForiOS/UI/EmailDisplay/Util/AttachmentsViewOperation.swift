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
    /**
     The `UIStackView`'s spacing is taken from `top`, the margins from `left` and `right`.
     */
    let insets = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)

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

    func guessScreenWidth() -> CGFloat {
        return UIScreen.main.bounds.width
    }

    override func main() {
        var attachmentViews = [UIView]()

        let maxWidth = guessScreenWidth() - insets.left - insets.right
        let spacing: CGFloat = insets.top
        var totalHeight: CGFloat = 0
        let attachments = eligibleAttachments()
        for att in attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data, let img = UIImage(data: imgData) {
                let view = UIImageView(image: img)
                if view.bounds.size.width > maxWidth {
                    let origWidth = view.bounds.size.width
                    view.bounds.size.width = maxWidth
                    view.bounds.size.height = round(maxWidth * view.bounds.size.height / origWidth)
                }
                view.contentMode = .scaleAspectFill
                attachmentViews.append(view)
                totalHeight += view.bounds.size.height
                totalHeight += spacing
            }
        }
        totalHeight -= spacing

        // The frame needed to place all attachment images
        let theFrame = CGRect(origin: CGPoint.zero,
                              size: CGSize(width: maxWidth, height: totalHeight))

        let stackedView = UIStackView(arrangedSubviews: attachmentViews)
        stackedView.axis = .vertical
        stackedView.distribution = .equalCentering
        stackedView.alignment = .center
        stackedView.spacing = spacing
        stackedView.frame = theFrame

        let footerView = UITableViewHeaderFooterView()
        let parentView = footerView.contentView
        footerView.frame = theFrame
        parentView.addSubview(stackedView)

        let c1 = NSLayoutConstraint(
            item: stackedView, attribute: .leading, relatedBy: .equal, toItem: parentView,
            attribute: .leading, multiplier: 1.0, constant: 0.0)
        let c2 = NSLayoutConstraint(
            item: stackedView, attribute: .top, relatedBy: .equal, toItem: parentView,
            attribute: .top, multiplier: 1.0, constant: 0.0)
        parentView.addConstraints([c1, c2])

        resultView = parentView
    }
}
