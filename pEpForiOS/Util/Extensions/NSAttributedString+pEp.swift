//
//  NSAttributedString+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel

extension NSAttributedString {

    public func textAttachments(range: NSRange? = nil) -> [BodyCellViewModel.TextAttachment] {
        let theRange = range ?? NSMakeRange(0, length)
        var allAttachments = [TextAttachment]()
        if theRange.location != NSNotFound {
            enumerateAttribute(
                NSAttributedString.Key.attachment, in: theRange,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) {
                    value, range, stop in
                if let attachment = value as? BodyCellViewModel.TextAttachment {
                        allAttachments.append(attachment)
                    }
            }
        }

        return allAttachments
    }

    public func textAttachments(string: String) -> [BodyCellViewModel.TextAttachment] {
        return textAttachments(range: NSMakeRange(0, string.count))
    }

    public func recipientTextAttachments(
        range: NSRange? = nil) -> [RecipientTextViewModel.TextAttachment] {
        let theRange = range ?? NSMakeRange(0, length)
        var allAttachments = [RecipientTextViewModel.TextAttachment]()
        if theRange.location != NSNotFound {
            enumerateAttribute(
                NSAttributedString.Key.attachment, in: theRange,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) {
                    value, range, stop in
                    if let attachment = value as? RecipientTextViewModel.TextAttachment {
                        allAttachments.append(attachment)
                    }
            }
        }
        return allAttachments
    }

    /// Removes (plain)text from the attributed string. Used for getting NSTextAttchments only
    /// which is considered the only thing left.
    /// - Returns: A string with all text removed. Assumed a string containing only NSTextAttachments.
    public func plainTextRemoved() -> NSAttributedString {
        var attachments: [NSTextAttachment] = textAttachments()
        attachments.append(contentsOf: recipientTextAttachments())
        let result: NSAttributedString
        if attachments.count > 0 {
            let new = NSMutableAttributedString()
            for at in attachments {
                let attachString = NSAttributedString(attachment: at)
                new.append(attachString)
            }
            new.addAttribute(NSAttributedString.Key.font,
                             value: UIFont.pepFont(style: .footnote, weight: .regular),
                             range: NSRange(location: 0, length: new.length)
            )
            new.addAttribute(NSAttributedString.Key.baselineOffset,
                             value: 3.0,
                             range: NSRange(location: 0, length: new.length))
            result = new
        } else {
            // There are no attachments, so all it can hold is plan text
            result = NSAttributedString(string: "")
        }

        return result
    }

    public func baselineOffsetRemoved() -> NSAttributedString {
        let createe = NSMutableAttributedString(attributedString: self)
        createe.addAttribute(NSAttributedString.Key.baselineOffset,
                             value: 0.0,
                             range: NSRange(location: 0,
                                            length: createe.length)
        )
        return createe
    }
}
