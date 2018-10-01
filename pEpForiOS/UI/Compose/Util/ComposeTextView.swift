
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
    
    private final var fontDescender: CGFloat = -7.0
    final var textBottomMargin: CGFloat = 25.0
    private final var imageFieldHeight: CGFloat = 66.0

    private let newLinePaddingRegEx = try! NSRegularExpression(
        pattern: ".*[^\n]+(\n){2,}$", options: [])

    let scrollUtil = TextViewInTableViewScrollUtil()

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
        
        let string = identity.userName ?? identity.address.trimmed()
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
            new.addAttribute(NSAttributedStringKey.baselineOffset, value: 3.0, range: NSRange(location: 0, length: new.length))
            attributedText = new
        }
    }

    public func toMarkdown() -> (String, [Attachment]) {
        return attributedText.convertToMarkDown()
    }

    public func addNewlinePadding() {
        // Does nothing for recipient text views.
    }

    /**
     Invoke any actions needed after the text has changed, i.e. forcing the table to
     pick up the new size and scrolling to the current cursor position.
     */
    public func layoutAfterTextDidChange(tableView: UITableView) {
        // Does nothing for recipient text views.
    }

    func scrollCaretToVisible(tableView: UITableView) {
        scrollUtil.scrollCaretToVisible(tableView: tableView, textView: self)
    }
}
