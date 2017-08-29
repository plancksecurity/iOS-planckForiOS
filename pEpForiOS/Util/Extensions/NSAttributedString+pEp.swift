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

    fileprivate let mimeUtil = MimeTypeUtil()

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
}
