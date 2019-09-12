//
//  Attachment+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 13.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

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
            return Attachment(data: image.pngData() ?? image.jpegData(compressionQuality: 1.0),
                              mimeType: mimeType,
                              fileName: assetUrl.absoluteString,
                              image: image,
                              assetUrl: assetUrl,
                              contentDisposition: contentDisposition,
                              session: session)
        }
    }
}
