//
//  NSAttributedString+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ToMarkdownDelegate: NSAttributedStringParsingDelegate {
    var attachments = [Attachment]()

    private let mimeUtil = MimeTypeUtil()

    func stringFor(attachment: NSTextAttachment) -> String? {
        if let textAttachment = attachment as? TextAttachment,
            let theAttachment = textAttachment.attachment {
            attachments.append(theAttachment)
            let count = attachments.count

            let theID = MessageID.generateUUID()
            let theExt = mimeUtil?.fileExtension(mimeType: theAttachment.mimeType) ?? "jpg"
            let cidBase = "attached-inline-image-\(count)-\(theExt)-\(theID)"
            let cidSrc = "cid:\(cidBase)"
            let cidUrl = "cid://\(cidBase)"
            theAttachment.fileName = cidUrl

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

extension NSAttributedString {
    func convertToMarkDown() -> (String, [Attachment]) {
        let theDelegate = ToMarkdownDelegate()
        let markdown = convert(delegate: theDelegate)
        return (markdown.trimmingCharacters(in: .whitespacesAndNewlines),
                theDelegate.attachments)
    }

    public func textAttachments(range: NSRange? = nil) -> [TextAttachment] {
        let theRange = range ?? NSMakeRange(0, length)
        var allAttachments = [TextAttachment]()
        if theRange.location != NSNotFound {
            enumerateAttribute(
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

    public func recipientTextAttachments(
        range: NSRange? = nil) -> [RecipientTextViewTextAttachment] {
        let theRange = range ?? NSMakeRange(0, length)
        var allAttachments = [RecipientTextViewTextAttachment]()
        if theRange.location != NSNotFound {
            enumerateAttribute(
                NSAttributedStringKey.attachment, in: theRange,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) {
                    value, range, stop in
                    if let attachment = value as? RecipientTextViewTextAttachment {
                        allAttachments.append(attachment)
                    }
            }
        }
        return allAttachments
    }

    public func plainTextRemoved() -> NSAttributedString {
        var attachments: [NSTextAttachment] = textAttachments()
        attachments.append(contentsOf: recipientTextAttachments())
        var result = self
        if attachments.count > 0 {
            let new = NSMutableAttributedString()
            for at in attachments {
                let attachString = NSAttributedString(attachment: at)
                new.append(attachString)
            }

            new.addAttribute(NSAttributedStringKey.font,
                             value: UIFont.pEpInput,
                             range: NSRange(location: 0, length: new.length)
            )
            new.addAttribute(NSAttributedStringKey.baselineOffset,
                             value: 3.0,
                             range: NSRange(location: 0, length: new.length))
            result = new
        }

        return result
    }
}

extension NSMutableAttributedString {
    @discardableResult public func bold(_ text:String) -> NSMutableAttributedString {
        let attrs:[NSAttributedStringKey: Any] =
            [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .callout)]

        let boldString = NSMutableAttributedString(string: text, attributes: attrs)
        self.append(boldString)
        return self
    }

    @discardableResult public func normal(_ text: String) -> NSMutableAttributedString {
        let attrs:[NSAttributedStringKey: Any] =
            [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body)]

        let normal =  NSMutableAttributedString(string: text, attributes: attrs)
        self.append(normal)
        return self
    }
}
