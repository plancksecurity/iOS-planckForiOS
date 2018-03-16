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
        if data == nil || AttachmentFilter.unviewableMimeTypes.contains(mimeType.lowercased()) {
            return false
        }
        return true
    }

    /// Trys to extract the contentID of the attachment from the `filename` field.
    /// Returns the CID (without "cid:") if `filename` contains it. Otherwize returns `nil`.
    var contentID: String? {
        guard let fn = fileName else {
            return nil
        }
        return fn.extractCid()
    }
}
