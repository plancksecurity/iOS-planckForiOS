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
    static private let supportedInlineImageUTIsToMimeType: [String:String] = [ kUTTypeJPEG as String: "image/jpeg" ]

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
}
