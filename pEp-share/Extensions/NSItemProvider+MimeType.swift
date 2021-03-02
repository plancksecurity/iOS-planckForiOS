//
//  NSItemProvider+MimeType.swift
//  pEp-share
//
//  Created by Dirk Zimmermann on 02.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import MobileCoreServices

extension NSItemProvider {
    /// - Returns: An image-related mime type if this provider has an item conforming to a known image UTI
    ///   that we support as inline attachment.
    public func supportedMimeTypeForInlineAttachment() -> String? {
        guard hasItemConformingToTypeIdentifier(kUTTypeImage as String) else {
            return nil
        }

        for (uti, mimeType) in NSItemProvider.supportedInlineImageUTIsToMimeType {
            if hasItemConformingToTypeIdentifier(uti) {
                return mimeType
            }
        }

        return nil
    }

    static private let supportedInlineImageUTIsToMimeType: [String:String] = [ kUTTypeJPEG as String: "image/jpeg" ]
}
