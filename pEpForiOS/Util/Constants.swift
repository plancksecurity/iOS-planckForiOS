//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

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

    public enum GeneralErrorCode: Int {
        case notImplemented = 1000
        case illegalState
        case invalidParameter
        case operationFailed
    }

    public enum NetworkError: Int {
        case timeout = 2000
        case authenticationFailed
        case connectionLost
        case connectionTerminated
        case connectionTimeout
    }

    public enum CoreDataErrorCode: Int {
        case couldNotInsertOrUpdate = 3000
        case folderDoesNotExist
        case cannotStoreMail
        case couldNotUpdateOrAddContact
        case couldNotStoreFolder
        case cannotFindAccountForEmail
        case cannotFindServerForAccount
    }

    public enum SmtpErrorCode: Int {
        case messageNotSent = 4000
        case transactionInitiationFailed
        case recipientIdentificationFailed
        case transactionResetFailed
        case authenticationFailed
        case connectionLost
        case connectionTerminated
        case connectionTimedOut
        case requestCancelled
    }

    /**
     Some errors shown to the user which are actually internal.
     */
    public enum InternalErrorCode: Int {
        case noModel = 5000
    }

    /**
     Errors dealing with the pEp engine.
     */
    public enum PepErrorCode: Int {
        case encryptionError = 6000
    }

    /**
     Errors dealing with IMAP.
     */
    public enum ImapErrorCode: Int {
        case unknownError = 7000
        case badResponseError
        case messageStoreFailed
        case folderCreateFailed
        case folderDeleteFailed
        case appendFailed
    }

    static func errorNotImplemented(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.notImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Not implemented",
                    comment: "General error description for operation that is not yet implemented"
                )])
        return error
    }

    static func errorIllegalState(_ component: String, stateName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.notImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Unexpected state: %@",
                    comment: "General error description for operation that encountered an unexpected state/callback, e.g. a 'message received' when waiting for a list of folders"),
                    stateName)])
        return error
    }

    static func errorIllegalState(_ component: String, errorMessage: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.notImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return error
    }

    static func errorInvalidParameter(_ component: String, errorMessage: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.invalidParameter.rawValue,
            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return error
    }

    static func errorOperationFailed(_ component: String, errorMessage: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.operationFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return error
    }

    static func errorFolderNotOpen(_ component: String, folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.illegalState.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Folder is not open: %@",
                    comment: "General error description for operation that needs an open folder, but there was none"),
                    folderName)])
        return error
    }

    static func errorFolderDoesNotExist(_ component: String,
                                                     folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.folderDoesNotExist.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Cannot store mail for non-existent folder: %@",
                    comment: "Error description when mail for non-existent folder gets stored"),
                    folderName) ])
        return error
    }

    static func errorCannotStoreMail(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.cannotStoreMail.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Cannot store mail",
                    comment: "General error description for not being able to store a mail")])
        return error
    }

    static func errorCouldNotUpdateOrAddContact(_ component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.couldNotUpdateOrAddContact.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Cannot store contact: %@",
                    comment: "Error description when not being able to update or store a contact"),
                    name)])
        return error
    }

    static func errorCouldNotStoreFolder(_ component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.couldNotStoreFolder.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Cannot store folder: %@",
                    comment: "Error description when not being able to store a folder"),
                    name)])
        return error
    }

    static func errorCannotFindAccountForEmail(
        _ component: String, email: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.cannotFindAccountForEmail.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "Cannot find account for email: %@", comment:
                    "Error description when not being able to fetch account by email"),
                    email)])
        return error
    }

    static func errorCannotFindServer(
        component: String, accountEmail: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.cannotFindServerForAccount.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "Cannot find server for account with email: %@", comment:
                    "Error description when not being able to fetch an account's server"),
                            accountEmail)])
        return error
    }

    static func errorTimeout(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.timeout.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Timeout",
                    comment: "General error description for a timeout")])
        return error
    }

    static func errorAuthenticationFailed(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.authenticationFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Authentication failed",
                    comment: "General error description for a failed authentication attempt")])
        return error
    }

    static func errorConnectionLost(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.connectionLost.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Connection lost",
                    comment: "General error description for a lost connection")])
        return error
    }

    static func errorConnectionTerminated(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.connectionLost.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Connection terminated",
                    comment: "General error description for a terminated connection")])
        return error
    }

    static func errorConnectionTimeout(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.connectionTimeout.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Connection timed out",
                    comment: "General error description for a timed out connection")])
        return error
    }

    static func errorSmtp(_ component: String, code: SmtpErrorCode) -> NSError {
        let error = NSError.init(
            domain: component, code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format:
                    NSLocalizedString("SMTP Error (%d)", comment: ""),
                    code.rawValue)])
        return error
    }

    static func errorEncryption(_ component: String, status: PEP_STATUS) -> NSError {
        let error = NSError.init(
            domain: component, code: PepErrorCode.encryptionError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: String.init(format: NSLocalizedString(
                "Could not encrypt message, pEp status: %d",
                comment: "Error message when the engine failed to encrypt a message."),
                status.rawValue)])
        return error
    }

    static func errorImapUnknown(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.unknownError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                "Unknown IMAP error", comment: "Unknown IMAP error.")])
        return error
    }

    static func errorImapBadResponse(_ component: String, response: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.badResponseError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: String.init(format: NSLocalizedString(
                "Error response from server: %@",
                comment: "Error message for a bad IMAP response."),
                response)])
        return error
    }

    static func errorMessageStoreFailed(_ component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.messageStoreFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                "IMAP: Could not update flags",
                comment: "IMAP error when flags could not be stored")])
        return error
    }

    static func errorFolderCreateFailed(_ component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.folderCreateFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "IMAP: Could not create folder '%@'",
                    comment: "IMAP error when folder could not be created"), name)])
        return error
    }

    static func errorFolderDeleteFailed(_ component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.folderDeleteFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "IMAP: Could not delete folder '%@'",
                    comment: "IMAP error when remote folder could not be deleted"), name)])
        return error
    }

    static func errorAppendFailed(_ component: String, folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.appendFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "IMAP: Could not append message to folder '%@'",
                    comment: "IMAP error when remote folder could not be deleted"),
                    folderName)])
        return error
    }
}
