//
//  MessageBodyTableViewCell.swift
//  MailComposer
//
//  Created by Yves Landert on 11/10/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

public class TextAttachment: NSTextAttachment {
    var attachment: Attachment?
    var identifier: String?
}

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

        delegate.didStartEditing(at: index, textView: theTextView)
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        assert(textView is ComposeMessageBodyTextView)

        guard let delegate = delegate as? MessageBodyCellDelegate,
            let theTextView = textView as? ComposeMessageBodyTextView else {
                return
        }

        delegate.didEndEditing(at: index, textView: theTextView)
    }
}

extension MessageBodyCell {
    public final func inline(attachment: Attachment) {
        guard let image = attachment.image else {
            Log.shared.errorAndCrash(component: #function, errorString: "No image")
            return
        }
        let textAttachment = TextAttachment()
        textAttachment.image = image
        textAttachment.attachment = attachment
        let imageString = NSAttributedString(attachment: textAttachment)
        
        textAttachment.bounds = CGRect.rect(withWidth: textView.bounds.width, ratioOf: image.size)
        
        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
        attrText.replaceCharacters(in: selectedRange, with: imageString)
        textView.attributedText = attrText
    }

    public final func allInlinedAttachments() -> [Attachment] {
        let attachments = textView.textAttachments()
        var mailAttachments = [Attachment]()
        attachments.forEach { (attachment) in
            if let attch = attachment.attachment {
                mailAttachments.append(attch)
            }
        }
        return mailAttachments
    }

    public func hasInlinedAttatchments() -> Bool {
        return allInlinedAttachments().count > 0
    }
}
