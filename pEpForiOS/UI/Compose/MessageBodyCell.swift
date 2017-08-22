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
    
    public var photos = [Attachment]()
    public var attachments = [Attachment]()
    
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
    public final func insert(_ attachment: Attachment) {
        photos.append(attachment)
        
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
    
    public final func addMovie(_ attachment: Attachment) {
        let amount = attachments.count
        let validAttachment = attachment
        
        if amount > 0 {
            let nameurl = URL(fileURLWithPath: attachment.fileName)
            let fileext = nameurl.pathExtension
            let name = nameurl.deletingPathExtension().lastPathComponent
            validAttachment.fileName = "\(name)_\(String(amount)).\(fileext)"
        }
        add(validAttachment)
    }
    
    public final func add(_ attachment: Attachment) {
        attachments.append(attachment)
        
        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
        let template = UIImage(named: "attatchment-icon")!
        let icon = template.attachment(attachment.fileName)
        let at = TextAttachment()
        at.image = icon
        at.attachment = attachment
        at.bounds = CGRect(x: 0, y: 0, width: icon.size.width, height: icon.size.height)
        
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        textView.attributedText = attrText
    }
    
    public final func allAttachments() -> [Attachment] {
        let attachments = textView.textAttachments()
        var mailAttachments = [Attachment]()
        attachments.forEach { (attachment) in
            if let attch = attachment.attachment {
                mailAttachments.append(attch)
            }
        }
        return mailAttachments
    }
}
