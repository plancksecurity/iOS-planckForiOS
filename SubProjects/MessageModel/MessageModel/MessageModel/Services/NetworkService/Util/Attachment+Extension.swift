//
//  Attachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

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

    /// Indicates if it's a calendar attachment
    var isICS: Bool {
        return mimeType == MimeTypeUtils.MimeType.ics.rawValue
    }

    /// Indicates if the attachment is Cid contained.
    public var isCidContained: Bool {
        var cidContained = false
        if let theCid = fileName?.extractCid() {
            cidContained = message?.longMessageFormatted?.contains(find: theCid) ?? false
        }
        return cidContained
    }
}
