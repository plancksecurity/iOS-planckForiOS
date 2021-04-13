//
//  BodyCellViewModel+TextAttachment.swift
//  pEp
//
//  Created by Andreas Buff on 30.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

// MARK: - BodyCellViewModel+TextAttachment

extension BodyCellViewModel {

    public class TextAttachment: NSTextAttachment {
        public var attachment: Attachment?
        public var identifier: String?

        public func cidInfo() -> (cidString: String?, attachment: Attachment?) {
            let nullResult: (cidString: String?, attachment: Attachment?) = (cidString: nil,
                                                                             attachment: nil)
            let mimeUtils = MimeTypeUtils()

            guard let attachment = attachment else {
                return (nil, nil)
            }

            var result = nullResult
            // Attachments in compose MUST be on a private Session, as they are in invalid state
            // (message == nil) and thus must not be seen nor saved on other Sessions.
            attachment.session.performAndWait {
                guard let mimeType = attachment.mimeType else {
                    result = nullResult
                    return
                }
                result.attachment = attachment

                let theID = UUID().uuidString + "@pretty.Easy.privacy"
                let theExt = mimeUtils?.fileExtension(fromMimeType: mimeType) ?? "jpg"
                let cidBase = "attached-inline-image-\(theExt)-\(theID)"
                let cidSrc = "cid:\(cidBase)"
                let cidUrl = "cid://\(cidBase)"
                attachment.fileName = cidUrl

                let alt = String.localizedStringWithFormat(
                    NSLocalizedString("Attached Image (%1$@)",
                                      comment: "Alt text for image attachment in markdown. Placeholders: Attachment number, extension."),
                    theExt)

                result.cidString = "![\(alt)](\(cidSrc))"
            }
            return result
        }
    }
}
