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

class ToMarkdownDelegate: NSAttributedStringParsingDelegate {
    var attachments = [Attachment]()

    private lazy var mimeUtils = MimeTypeUtils()
    
    func stringFor(attachment: NSTextAttachment) -> String? {
        guard
            let textAttachment = attachment as? TextAttachment,
            let attachment = textAttachment.attachment
            else {
                return nil
        }

        var result: String? = nil
        // Attachments in compose MUST be on a private Session, as they are in invalid state
        // (message == nil) and thus must not be seen nor saved on other Sessions.
        attachment.session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let mimeType = attachment.mimeType else {
                result = nil
                return
            }

            me.attachments.append(attachment)
            let count = me.attachments.count

            let theID = UUID().uuidString + "@pretty.Easy.privacy"
            let theExt = me.mimeUtils?.fileExtension(fromMimeType: mimeType) ?? "jpg"
            let cidBase = "attached-inline-image-\(count)-\(theExt)-\(theID)"
            let cidSrc = "cid:\(cidBase)"
            let cidUrl = "cid://\(cidBase)"
            attachment.fileName = cidUrl

            let alt = String.localizedStringWithFormat(
                NSLocalizedString("Attached Image %1$d (%2$@)",
                                  comment: "Alt text for image attachment in markdown. Placeholders: Attachment number, extension."),
                count, theExt)

            result = "![\(alt)](\(cidSrc))"
        }
        return result
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
                NSAttributedString.Key.attachment, in: theRange,
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

    public func toHtml() -> (plainText: String, html: String?) {

        let htmlDocAttribKey = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]

        // conversion NSTextAttachment with image to <img src.../> html tag with cid:{cid}

        let htmlConv = HtmlConversions()
        let plainTextAndHtml = htmlConv.citationVerticalLineToBlockquote(aString: self)
        let plainText = plainTextAndHtml.plainText

        let mutableAttribString = NSMutableAttributedString(attributedString: plainTextAndHtml.attribString)

        var images: [NSRange : String] = [:]

        mutableAttribString.enumerateAttribute(.attachment,
                                               in: mutableAttribString.wholeRange()) { (value, range, stop) in
            if let attachment = value as? TextAttachment {
                let delegate = ToMarkdownDelegate()
                if let stringForAttachment = delegate.stringFor(attachment: attachment) {
                    if delegate.attachments.count > 0 {
                        images[range] = stringForAttachment.cleanAttachments
                    }
                }
            }
        }

        for item in images.reversed() {
            mutableAttribString.replaceCharacters(in: item.key, with: item.value)
        }

        guard let htmlData = try? mutableAttribString.data(from: mutableAttribString.wholeRange(),
                                            documentAttributes: htmlDocAttribKey) else {
                                                return (plainText: plainText, html: nil)
        }
        let html = (String(data: htmlData, encoding: .utf8) ?? "")
            .replaceMarkdownImageSyntaxToHtmlSyntax()
            .replacingOccurrences(of: "›", with: "<blockquote type=\"cite\">")
            .replacingOccurrences(of: "‹", with: "</blockquote>")


        return (plainText: plainText, html: html)
    }
}

extension NSMutableAttributedString {
    @discardableResult public func bold(_ text:String) -> NSMutableAttributedString {
        let attrs:[NSAttributedString.Key: Any] =
            [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .callout)]

        let boldString = NSMutableAttributedString(string: text, attributes: attrs)
        self.append(boldString)
        return self
    }

    @discardableResult public func normal(_ text: String) -> NSMutableAttributedString {
        let attrs:[NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .body)]
        let normal =  NSMutableAttributedString(string: text, attributes: attrs)
        self.append(normal)
        return self
    }
}
