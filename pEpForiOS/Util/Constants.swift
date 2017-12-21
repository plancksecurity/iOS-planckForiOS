//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

open class Constants {
    /** Settings key for storing the email of the last used account */
    static let kSettingLastAccountEmail = "kSettingLastAccountEmail"

    /** MIME content type for plain text */
    open static let contentTypeText = "text/plain"

    /** MIME content type for HTML */
    open static let contentTypeHtml = "text/html"

    /**
     Mime type for the "Version" attachment of PGP/MIME.
     */
    open static let contentTypePGPEncrypted = "application/pgp-encrypted"

    /**
     Content type for MIME multipart/mixed.
     */
    open static let contentTypeMultipartMixed = "multipart/mixed"

    /**
     Content type for MIME multipart/related.
     */
    open static let contentTypeMultipartRelated = "multipart/related"

    /**
     Content type for MIME multipart/encrypted.
     */
    open static let contentTypeMultipartEncrypted = "multipart/encrypted"

    /**
     Protocol for PGP/MIME application/pgp-encrypted.
     */
    open static let protocolPGPEncrypted = "application/pgp-encrypted"

    /**
     Content type for MIME multipart/alternative.
     */
    open static let contentTypeMultipartAlternative = "multipart/alternative"

    /**
     The MIME type for attached emails (e.g., when forwarding).
     */
    open static let attachedEmailMimeType = "message/rfc822"

    static let defaultFileName = NSLocalizedString("unknown",
                                                   comment:
        "file name used for unnamed attachments")
}
