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

    fileprivate let newLinePaddingRegEx: NSRegularExpression?

    required public init?(coder aDecoder: NSCoder) {
        do {
            newLinePaddingRegEx = try NSRegularExpression(
                pattern: ".*[^\n]+(\n){2,}$", options: [])
        } catch let err {
            Log.shared.errorAndCrash(component: #function, error: err)
            newLinePaddingRegEx = nil
        }
        super.init(coder: aDecoder)
    }

    public final var fieldHeight: CGFloat {
        get {
            let size = sizeThatFits(CGSize(width: frame.size.width,
                                           height: CGFloat(Float.greatestFiniteMagnitude)))
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
        
    public final func insertImage(_ identity: Identity, _ hasName: Bool = false, maxWidth: CGFloat = 0.0) {
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

    public final func textAttachments(range: NSRange? = nil) -> [TextAttachment] {
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

    public final func textAttachments(string: String) -> [TextAttachment] {
        return textAttachments(range: NSMakeRange(0, string.count))
    }
    
    public final func removePlainText() {
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
    
    public final func removeAttachments() {
        let mutAttrString = NSMutableAttributedString(attributedString: attributedText)
        let range = NSMakeRange(0, mutAttrString.length)
        
        mutAttrString.enumerateAttributes(in: range, options: .reverse) {
            (attributes, theRange, stop) -> Void in
            for attachment in attributes {
                if attachment.value is NSTextAttachment {
                    mutAttrString.removeAttribute(attachment.0, range: theRange)
                }
            }
        }
    }

    public func toMarkdown() -> (String, [Attachment]) {
        return attributedText.convertToMarkDown()
    }

    /**
     Makes sure that the text has at least two newlines appended, so all content
     is always visible.
     */
    public func addNewlinePadding() {
        if fieldModel?.type != .content {
            return
        }
        func paddedByDoubleNewline(pureText: NSAttributedString) -> Bool {
            let numMatches = newLinePaddingRegEx?.numberOfMatches(
                in: pureText.string, options: [], range: pureText.wholeRange()) ?? 1
            return numMatches > 0
        }

        if text.isEmpty {
            return
        }
        var changed = false
        let theText = NSMutableAttributedString(attributedString: attributedText)
        let theRange = selectedRange
        //the text always must end with two \n
        while (!theText.string.endsWith("\n\n")) {
            let appendedString = NSMutableAttributedString(string: "\n")
            appendedString.addAttribute(NSAttributedStringKey.font,
                                        value: UIFont.pEpInput,
                                        range: appendedString.wholeRange()
            )

            theText.append(appendedString)
            changed = true
        }
        if changed {
            attributedText = theText
            selectedRange = theRange
        }
    }
}
