//
//  MessageBodyTableViewCell.swift
//  MailComposer
//
//  Created by Yves Landert on 11/10/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

class MessageBodyCell: ComposeCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.text.append(.pepSignature)
    }

    override func textViewDidBeginEditing(_ textView: UITextView) {
        assert(textView is ComposeMessageBodyTextView)

        guard let delegate = delegate as? MessageBodyCellDelegate,
            let theTextView = textView as? ComposeMessageBodyTextView else {
                return
        }

        delegate.didStartEditing(at: index, composeTextView: theTextView)
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        assert(textView is ComposeMessageBodyTextView)

        guard let delegate = delegate as? MessageBodyCellDelegate,
            let theTextView = textView as? ComposeMessageBodyTextView else {
                return
        }

        delegate.didEndEditing(at: index, composeTextView: theTextView)
    }
}

extension MessageBodyCell {
    public final func inline(attachment: Attachment) {
        guard let image = attachment.image else {
            Log.shared.errorAndCrash(component: #function, errorString: "No image")
            return
        }
        // Workaround: If the image has a higher resolution than that, UITextView has serious
        // performance issues (delay typing). I suspect we are causing them elswhere though.
        guard let scaledImage = image.resized(newWidth: frame.size.width / 2, useAlpha: false)
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error resizing")
                return
        }

        let textAttachment = TextAttachment()
        textAttachment.image = scaledImage
        textAttachment.attachment = attachment
        textAttachment.bounds = CGRect.rect(withWidth: textView.bounds.width,
                                            ratioOf: scaledImage.size)
        let imageString = NSAttributedString(attachment: textAttachment)

        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
        attrText.replaceCharacters(in: selectedRange, with: imageString)
        textView.attributedText = attrText
    }

    public final func allInlinedAttachments() -> [Attachment] {
        let attachments = textView.attributedText.textAttachments()
        var mailAttachments = [Attachment]()
        attachments.forEach { (attachment) in
            if let attch = attachment.attachment {
                attch.contentDisposition = .inline
                mailAttachments.append(attch)
            }
        }
        return mailAttachments
    }

    public func hasInlinedAttatchments() -> Bool {
        return allInlinedAttachments().count > 0
    }
}
