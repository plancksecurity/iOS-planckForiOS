//
//  Attachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Attachment {
    /// Is this attachment meant to show to the user?
    public func isViewable() -> Bool {
        guard let mime = mimeType else {
            // It happens that we are getting super malformed (spam) mails, so we need to handle
            // this, which we do by ignoring the attachment.
            // I decided to crash in debug anyway to find homebrewn mime type issues early.
            Log.shared.errorAndCrash("no mime type")
            return false
        }
        if data == nil || MimeTypeUtils.unviewableMimeTypes.contains(mime.lowercased()) {
            return false
        }
        if contentDisposition == .inline,
        mimeType?.lowercased() == MimeTypeUtils.MimeType.plainText.rawValue {
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
    public var contentID: String? {
        guard let fn = fileName else {
            return nil
        }
        return fn.extractCid()
    }

    /// Wheter or not the attachment is inlined in a HTML mail body.
    public var isInlined: Bool {
        return contentDisposition == .inline
    }
}
