
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
    final var textBottomMargin: CGFloat = 25.0
    fileprivate final var imageFieldHeight: CGFloat = 66.0

    fileprivate let newLinePaddingRegEx = try! NSRegularExpression(
        pattern: ".*[^\n]+(\n){2,}$", options: [])

    public var fieldHeight: CGFloat {
        get {
            let size = sizeThatFits(CGSize(width: frame.size.width,
                                           height: CGFloat(Float.greatestFiniteMagnitude)))
            return size.height + textBottomMargin
        }
    }
    
    public func scrollToBottom() {
        if fieldHeight >= imageFieldHeight {
            setContentOffset(CGPoint(x: 0.0, y: fieldHeight - imageFieldHeight), animated: true)
        }
    }
    
    public func scrollToTop() {
        contentOffset = .zero
    }
        
    public func insertImage(_ identity: Identity, _ hasName: Bool = false,
                            maxWidth: CGFloat = 0.0) {
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        
        let string = identity.userName ?? identity.address.trim
        let img = ComposeHelper.recepient(string, textColor: .pEpGreen, maxWidth: maxWidth-20.0)
        let at = TextAttachment()
        at.image = img
        at.bounds = CGRect(x: 0, y: fontDescender, width: img.size.width, height: img.size.height)
        
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSAttributedStringKey.font,
            value: UIFont.pEpInput,
            range: NSRange(location: 0, length: attrText.length)
        )
        attributedText = attrText
    }

    public func textAttachments(range: NSRange? = nil) -> [TextAttachment] {
        let theRange = range ?? NSMakeRange(0, attributedText.length)
        var allAttachments = [TextAttachment]()
        if theRange.location != NSNotFound {
            attributedText.enumerateAttribute(
                NSAttributedStringKey.attachment, in: theRange,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) {
                    value, range, stop in
                    if let attachment = value as? TextAttachment {
                        allAttachments.append(attachment)
                    }
            }
        }

        return allAttachments
    }

    public func textAttachments(string: String) -> [TextAttachment] {
        return textAttachments(range: NSMakeRange(0, string.count))
    }
    
    public func removePlainText() {
        let attachments = textAttachments()
        if attachments.count > 0  {
            let new = NSMutableAttributedString()
            for at in attachments {
                let attachString = NSAttributedString(attachment: at)
                new.append(attachString)
            }
            
            new.addAttribute(NSAttributedStringKey.font,
                value: UIFont.pEpInput,
                range: NSRange(location: 0, length: new.length)
            )
            attributedText = new
        }
    }

    public func toMarkdown() -> (String, [Attachment]) {
        return attributedText.convertToMarkDown()
    }

    /**
     Makes sure that the text has at least two newlines appended, so all content
     is always visible.
     Should only affect the actual message content, if at all.
     */
    public func addNewlinePadding() {
    }
}
