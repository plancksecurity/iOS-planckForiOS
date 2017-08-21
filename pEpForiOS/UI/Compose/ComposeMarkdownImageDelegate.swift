//
//  ComposeMarkdownImageDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Relates all markdown image references in an outgoing message text to the
 corresponding attachment, thereby effectively producing markdown with inlined
 attached images.
 */
class ComposeMarkdownImageDelegate {
    struct AttachmentInfo {
        let cidUrl: String
        let alt: String
    }

    let attachments: [Attachment]
    var attachmentInfos = [AttachmentInfo]()

    fileprivate let mimeUtil = MimeTypeUtil()
    fileprivate var attachmentCount = 0

    init(attachments: [Attachment]) {
        self.attachments = attachments
    }
}

extension ComposeMarkdownImageDelegate : MarkdownImageDelegate {
    func img(src: String, alt: String?) -> (String, String) {
        let attachment = attachments[attachmentCount]

        let theID = Foundation.UUID().uuidString
        let theExt = mimeUtil?.fileExtension(mimeType: attachment.mimeType) ?? "jpg"
        let cidSrc = "cid:attached-inline-image-\(attachmentCount)-\(theExt)-\(theID)"

        attachmentCount += 1
        let alt = String(
            format: NSLocalizedString("Attached Image %1d (%2@)", comment: "image attachment name"),
            attachmentCount, theExt)
        attachmentInfos.append(AttachmentInfo(cidUrl: cidSrc, alt: alt))

        attachment.fileName = cidSrc

        return (cidSrc, alt)
    }
}
