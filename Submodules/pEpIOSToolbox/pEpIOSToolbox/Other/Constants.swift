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
    static let contentTypeText = "text/plain"

    /** MIME content type for HTML */
    static let contentTypeHtml = "text/html"

    /**
     Mime type for the "Version" attachment of PGP/MIME.
     */
    static let contentTypePGPEncrypted = "application/pgp-encrypted"

    /**
     Content type for MIME multipart/mixed.
     */
    static let contentTypeMultipartMixed = "multipart/mixed"

    /**
     Content type for MIME multipart/related.
     */
    static let contentTypeMultipartRelated = "multipart/related"

    /**
     Content type for MIME multipart/encrypted.
     */
    static let contentTypeMultipartEncrypted = "multipart/encrypted"

    /**
     Protocol for PGP/MIME application/pgp-encrypted.
     */
    static let protocolPGPEncrypted = "application/pgp-encrypted"

    /**
     Content type for MIME multipart/alternative.
     */
    static let contentTypeMultipartAlternative = "multipart/alternative"

    /**
     The MIME type for attached emails (e.g., when forwarding).
     */
    static let attachedEmailMimeType = "message/rfc822"
}
