//
//  ComposeTextView.swift
//
//  Created by Igor Vojinovic on 11/4/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

open class ComposeTextView: UITextView {
    public var fieldModel: ComposeFieldModel?
    
    fileprivate final var fontDescender: CGFloat = -7.0
    fileprivate final var textBottomMargin: CGFloat = 25.0
    fileprivate final var imageFieldHeight: CGFloat = 66.0
    
    public final var fieldHeight: CGFloat {
        get {
            let size = sizeThatFits(CGSize(width: frame.size.width, height: CGFloat(Float.greatestFiniteMagnitude)))
            return size.height + textBottomMargin
        }
    }
    
    public final func scrollToBottom() {
        if fieldHeight >= imageFieldHeight {
            setContentOffset(CGPoint(x: 0.0, y: fieldHeight - imageFieldHeight), animated: true)
        }
    }
    
    public final func scrollToTop() {
        contentOffset = .zero
    }
        
    public final func insertImage(_ identity: Identity, _ hasName: Bool = false) {
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        
        let string = identity.userName ?? identity.address.trim
        let img = ComposeHelper.recepient(string, textColor: .black)
        let at = TextAttachment()
        at.image = img
        at.bounds = CGRect(x: 0, y: fontDescender, width: img.size.width, height: img.size.height)
        
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSFontAttributeName,
            value: UIFont.pEpInput,
            range: NSRange(location: 0, length: attrText.length)
        )
        attributedText = attrText
    }
    
    public final func textAttachments(range: NSRange? = nil) -> [TextAttachment] {
        let theRange = range ?? NSMakeRange(0, attributedText.length)
        var allAttachments = [TextAttachment]()
        if theRange.length > 0 {
            attributedText.enumerateAttribute(
                NSAttachmentAttributeName, in: theRange,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) {
                    value, range, stop in
                    if let attachment = value as? TextAttachment {
                        allAttachments.append(attachment)
                    }
            }
        }
        
        return allAttachments
    }
    
    public final func textAttachments(string: String) -> [TextAttachment] {
        return textAttachments(range: NSMakeRange(0, string.characters.count))
    }
    
    public final func removePlainText() {
        let attachments = textAttachments()
        if attachments.count > 0  {
            let new = NSMutableAttributedString()
            for at in attachments {
                let attachString = NSAttributedString(attachment: at)
                new.append(attachString)
            }
            
            new.addAttribute(NSFontAttributeName,
                value: UIFont.pEpInput,
                range: NSRange(location: 0, length: new.length)
            )
            attributedText = new
        }
    }
    
    public final func removeAttachments() {
        let mutAttrString = NSMutableAttributedString(attributedString: attributedText)
        let range = NSMakeRange(0, mutAttrString.length)
        
        mutAttrString.enumerateAttributes(in: range, options: .reverse) { (attributes, theRange, stop) -> Void in
            for attachment in attributes {
                if attachment.value is NSTextAttachment {
                    mutAttrString.removeAttribute(attachment.0, range: theRange)
                }
            }
        }
    }

    class ToMarkdownDelegate: NSAttributedStringParsingDelegate {
        var attachments = [Attachment]()

        fileprivate let mimeUtil = MimeTypeUtil()

        func stringFor(attachment: NSTextAttachment) -> String? {
            if let textAttachment = attachment as? TextAttachment,
                let theAttachment = textAttachment.attachment {
                attachments.append(theAttachment)
                let count = attachments.count

                let theID = MessageID.generateUUID()
                let theExt = mimeUtil?.fileExtension(mimeType: theAttachment.mimeType) ?? "jpg"
                let cidSrc = "cid:attached-inline-image-\(count)-\(theExt)-\(theID)"

                theAttachment.fileName = cidSrc

                let alt = String(
                    format: NSLocalizedString("Attached Image %1d (%2@)",
                                              comment: "image attachment name"),
                    count, theExt)

                return "![\(alt)](\(cidSrc))"
            }
            return nil
        }

        func stringFor(string: String) -> String? {
            return string
        }
    }

    public func toMarkdown() -> (String, [Attachment]) {
        let theDelegate = ToMarkdownDelegate()
        let markdown = attributedText.convert(delegate: theDelegate)
        return (markdown, theDelegate.attachments)
    }
}
