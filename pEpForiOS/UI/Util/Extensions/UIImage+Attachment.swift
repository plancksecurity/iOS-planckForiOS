//
//  UIImage+Attachment.swift
//  pEpForiOS
//
//  Created by Martín Brude on 22/6/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension UIImage {

    /// Get an inlined Attachment
    ///
    /// - Parameters:
    ///   - fileName: The image filename
    ///   - imageData: The image data
    ///   - session: The session to work on
    /// - Returns: The Attachment
    func inlinedAttachment(fileName: String, imageData: Data, in session: Session) -> Attachment {
        let nsFileName = fileName as NSString
        let mimeType = MimeTypeUtils.mimeType(fromFileExtension: nsFileName.pathExtension)
        return Attachment(data: jpegData(compressionQuality: 1.0),
                          mimeType: mimeType,
                          fileName: fileName,
                          image: self,
                          contentDisposition: .inline,
                          session: session)
    }
}
