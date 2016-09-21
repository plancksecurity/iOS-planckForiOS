//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class Constants {
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

    public enum GeneralErrorCode: Int {
        case NotImplemented = 1000
        case IllegalState
        case InvalidParameter
        case OperationFailed
    }

    public enum NetworkError: Int {
        case Timeout = 2000
        case AuthenticationFailed
        case ConnectionLost
        case ConnectionTerminated
        case ConnectionTimeout
    }

    public enum CoreDataErrorCode: Int {
        case CouldNotInsertOrUpdate = 3000
        case FolderDoesNotExist
        case CannotStoreMail
        case CouldNotUpdateOrAddContact
        case CouldNotStoreFolder
        case CannotFindAccountForEmail
    }

    public enum SmtpErrorCode: Int {
        case MessageNotSent = 4000
        case TransactionInitiationFailed
        case RecipientIdentificationFailed
        case TransactionResetFailed
        case AuthenticationFailed
        case ConnectionLost
        case ConnectionTerminated
        case ConnectionTimedOut
        case RequestCancelled
    }

    /**
     Some errors shown to the user which are actually internal.
     */
    public enum InternalErrorCode: Int {
        case NoModel = 5000
    }

    /**
     Errors dealing with the pEp engine.
     */
    public enum PepErrorCode: Int {
        case EncryptionError = 6000
    }

    /**
     Errors dealing with IMAP.
     */
    public enum ImapErrorCode: Int {
        case UnknownError = 7000
        case BadResponseError
        case MessageStoreFailed
        case FolderCreateFailed
        case FolderDeleteFailed
        case AppendFailed
    }

    static func errorNotImplemented(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.NotImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Not implemented",
                    comment: "General error description for operation that is not yet implemented"
                )])
        return error
    }

    static func errorIllegalState(component: String, stateName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.NotImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Unexpected state: %@",
                    comment: "General error description for operation that encountered an unexpected state/callback, e.g. a 'message received' when waiting for a list of folders"),
                    stateName)])
        return error
    }

    static func errorIllegalState(component: String, errorMessage: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.NotImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return error
    }

    static func errorInvalidParameter(component: String, errorMessage: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.InvalidParameter.rawValue,
            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return error
    }

    static func errorOperationFailed(component: String, errorMessage: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.OperationFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return error
    }

    static func errorFolderNotOpen(component: String, folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.IllegalState.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Folder is not open: %@",
                    comment: "General error description for operation that needs an open folder, but there was none"),
                    folderName)])
        return error
    }

    static func errorFolderDoesNotExist(component: String,
                                                     folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.FolderDoesNotExist.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Cannot store mail for non-existent folder: %@",
                    comment: "Error description when mail for non-existent folder gets stored"),
                    folderName) ])
        return error
    }

    static func errorCannotStoreMail(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.CannotStoreMail.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Cannot store mail",
                    comment: "General error description for not being able to store a mail")])
        return error
    }

    static func errorCouldNotUpdateOrAddContact(component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.CouldNotUpdateOrAddContact.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Cannot store contact: %@",
                    comment: "Error description when not being able to update or store a contact"),
                    name)])
        return error
    }

    static func errorCouldNotStoreFolder(component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.CouldNotStoreFolder.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString("Cannot store folder: %@",
                    comment: "Error description when not being able to store a folder"),
                    name)])
        return error
    }

    static func errorCannotFindAccountForEmail(
        component: String, email: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.CannotFindAccountForEmail.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "Cannot find account for email: %@", comment:
                    "Error description when not being able to fetch account by email"),
                    email)])
        return error
    }

    static func errorTimeout(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.Timeout.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Timeout",
                    comment: "General error description for a timeout")])
        return error
    }

    static func errorAuthenticationFailed(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.AuthenticationFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Authentication failed",
                    comment: "General error description for a failed authentication attempt")])
        return error
    }

    static func errorConnectionLost(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.ConnectionLost.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Connection lost",
                    comment: "General error description for a lost connection")])
        return error
    }

    static func errorConnectionTerminated(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.ConnectionLost.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Connection terminated",
                    comment: "General error description for a terminated connection")])
        return error
    }

    static func errorConnectionTimeout(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: NetworkError.ConnectionTimeout.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Connection timed out",
                    comment: "General error description for a timed out connection")])
        return error
    }

    static func errorSmtp(component: String, code: SmtpErrorCode) -> NSError {
        let error = NSError.init(
            domain: component, code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format:
                    NSLocalizedString("SMTP Error (%d)", comment: ""),
                    code.rawValue)])
        return error
    }

    static func errorEncryption(component: String, status: PEP_STATUS) -> NSError {
        let error = NSError.init(
            domain: component, code: PepErrorCode.EncryptionError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: String.init(format: NSLocalizedString(
                "Could not encrypt message, pEp status: %d",
                comment: "Error message when the engine failed to encrypt a message."),
                status.rawValue)])
        return error
    }

    static func errorImapUnknown(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.UnknownError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                "Unknown IMAP error", comment: "Unknown IMAP error.")])
        return error
    }

    static func errorImapBadResponse(component: String, response: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.BadResponseError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: String.init(format: NSLocalizedString(
                "Bad response from server: @%",
                comment: "Error message for a bad IMAP response."),
                response)])
        return error
    }

    static func errorMessageStoreFailed(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.MessageStoreFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                "IMAP: Could not update flags",
                comment: "IMAP error when flags could not be stored")])
        return error
    }

    static func errorFolderCreateFailed(component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.FolderCreateFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "IMAP: Could not create folder '%@'",
                    comment: "IMAP error when folder could not be created"), name)])
        return error
    }

    static func errorFolderDeleteFailed(component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.FolderDeleteFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "IMAP: Could not delete folder '%@'",
                    comment: "IMAP error when remote folder could not be deleted"), name)])
        return error
    }

    static func errorAppendFailed(component: String, folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ImapErrorCode.AppendFailed.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                String.init(format: NSLocalizedString(
                    "IMAP: Could not append message to folder '%@'",
                    comment: "IMAP error when remote folder could not be deleted"),
                    folderName)])
        return error
    }
}