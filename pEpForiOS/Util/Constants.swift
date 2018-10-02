//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

struct Constants {
    /** Settings key for storing the email of the last used account */
    static let kSettingLastAccountEmail = "kSettingLastAccountEmail"

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

    static let defaultFileName = NSLocalizedString("unnamed",
                                                   comment:
        "file name used for unnamed attachments")

    /// Storyboard ID to instantiate ComposeViewController
    /// Is not in ComposeViewController.swift as it is the ID of the NavigationController that
    /// holds the ViewController, which the ViewController has no knowledge of.
    static let composeSceneStoryboardId = "ReplyNavigation"

    /// Name of Storyboard that contains ComposeViewController.
    static let composeSceneStoryboard = "Main"

    /// Name of Storyboard that contains AddToContactsViewController.
    static let addToContactsStoryboard = "Reusable"

    /// Name of Storyboard that contains SuggestTableViewController.
    static let suggestionsStoryboard = "Reusable"
}
