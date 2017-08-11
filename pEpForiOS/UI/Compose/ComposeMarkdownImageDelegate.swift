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
class ComposeMarkdownImageDelegate: MarkdownImageDelegate {
    let attachments: [Attachment]

    private var attachmentCount = 0

    init(attachments: [Attachment]) {
        self.attachments = attachments
    }

    func img(src: String, alt: String?) -> (String, String) {
        let _ = attachments[attachmentCount]
        attachmentCount += 1
        let cidName = "attached\(attachmentCount)"
        let attchName = String(
            format: NSLocalizedString("Image_%1d.%2@", comment: "image attachment name"),
            attachmentCount, "jpg")
        return (cidName, attchName)
    }
}
