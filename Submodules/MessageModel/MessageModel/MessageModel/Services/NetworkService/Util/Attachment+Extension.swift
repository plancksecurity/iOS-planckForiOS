//
//  Attachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

extension Attachment {
    /// Is this attachment meant to show to the user?
    func isViewable() -> Bool {
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
}
