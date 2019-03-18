//
//  Attachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension Attachment {
    /**
     Can this attachment be shown in the app?
     */
    public func isViewable() -> Bool {
        guard let type = mimeType else {
            return false
        }
        if data == nil || AttachmentFilter.unviewableMimeTypes.contains(type.lowercased()) {
            return false
        }
        return true
    }

    var isInlinedPlainText: Bool {
        return mimeType == "text/plain" && isInlined
    }

    /// Trys to extract the contentID of the attachment from the `filename` field.
    /// Returns the CID (without `cid:` or `cid://`) if `filename` contains it.
    /// Otherwize `nil` is returned.
    var contentID: String? {
        guard let fn = fileName else {
            return nil
        }
        return fn.extractCid()
    }

    /// Wheter or not the attachment is inlined in a HTML mail body.
    var isInlined: Bool {
        return contentDisposition == .inline
    }
}
