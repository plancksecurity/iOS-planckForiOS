//
//  Attachment+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 13.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension Attachment {

    public static func createFromAsset(mimeType: String,
                                       assetUrl: URL,
                                       image: UIImage,
                                       contentDisposition: ContentDispositionType,
                                       session: Session = Session.main) -> Attachment {
        var urlExtension = assetUrl.pathExtension
        // We do not support HEIC for inlined images. Convert to JPG.
        if urlExtension == "HEIC" && contentDisposition == .inline,
            let jpgData = image.jpegData(compressionQuality: 0.7), // We might want to ask the user for a size
            let jpg = UIImage(data: jpgData) {
            urlExtension = "JPG"
            let mime = "image/jpeg"
            return Attachment(data: jpgData,
                              mimeType: mime,
                              image:jpg,
                              contentDisposition: .inline,
                              session: session)
        } else {
            return Attachment(data: image.jpegData(compressionQuality: 0.7),
                              mimeType: mimeType,
                              fileName: assetUrl.absoluteString,
                              image: image,
                              assetUrl: assetUrl,
                              contentDisposition: contentDisposition,
                              session: session)
        }
    }

    /// Create an Attachment with content disposition inline.
    ///
    /// - Parameters:
    ///   - image: The image of the attachment
    ///   - fileName: The filename
    ///   - session: The session to work on
    /// - Returns: The attachment 
    public static func createInlinedWith(image: UIImage, fileName: String? = "public.jpg", session: Session) -> Attachment {
        return Attachment(data: image.jpegData(compressionQuality: 0.7), mimeType: MimeTypeUtils.MimeType.defaultMimeType.rawValue, fileName: fileName, image: image, contentDisposition: ContentDispositionType.inline, session: session)
    }
}
