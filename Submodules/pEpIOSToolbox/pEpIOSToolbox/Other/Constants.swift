//
//  Constants.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 22.02.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

public struct Constants {
    /** MIME content type for plain text */
    public static let contentTypeText = "text/plain"

    /** MIME content type for HTML */
    public static let contentTypeHtml = "text/html"

    /**
     Mime type for the "Version" attachment of PGP/MIME.
     */
    public static let contentTypePGPEncrypted = "application/pgp-encrypted"

    /**
     Content type for MIME multipart/mixed.
     */
    public static let contentTypeMultipartMixed = "multipart/mixed"

    /**
     Content type for MIME multipart/related.
     */
    public static let contentTypeMultipartRelated = "multipart/related"

    /**
     Content type for MIME multipart/encrypted.
     */
    public static let contentTypeMultipartEncrypted = "multipart/encrypted"

    /**
     Protocol for PGP/MIME application/pgp-encrypted.
     */
    public static let protocolPGPEncrypted = "application/pgp-encrypted"

    /**
     Content type for MIME multipart/alternative.
     */
    public static let contentTypeMultipartAlternative = "multipart/alternative"

    /**
     The MIME type for attached emails (e.g., when forwarding).
     */
    public static let attachedEmailMimeType = "message/rfc822"
}
