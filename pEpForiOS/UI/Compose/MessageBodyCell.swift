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
        super.textViewDidBeginEditing(textView)
        
        guard let delegate = delegate as? MessageBodyCellDelegate else { return }
        delegate.didStartEditing(at: index)
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        
        guard let delegate = delegate as? MessageBodyCellDelegate else { return }
        delegate.didEndEditing(at: index)
    }
}

extension MessageBodyCell {
    public final func inline(attachment: Attachment) {
        let textAttachment = TextAttachment()
        textAttachment.image = attachment.image
        textAttachment.attachment = attachment
        let imageString = NSAttributedString(attachment: textAttachment)
        
        textAttachment.bounds = obtainContainerToMaintainRatio(textView.bounds.width,
                                                               rectangle: (attachment.image?.size)!)
        
        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
        attrText.replaceCharacters(in: selectedRange, with: imageString)
        textView.attributedText = attrText
    }
    
    fileprivate final func obtainContainerToMaintainRatio(_ fixedWidth: CGFloat,
                                                          rectangle: CGSize) -> CGRect {
        let fixRatio = rectangle.width / rectangle.height
        let newHeight = fixedWidth / fixRatio
        return CGRect(x: 0, y: 0, width: fixedWidth, height: newHeight)
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
