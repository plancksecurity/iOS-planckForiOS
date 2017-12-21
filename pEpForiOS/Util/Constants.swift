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

    public enum GeneralErrorCode: Int { //BUFF: done
        case notImplemented = 1000
        case illegalState
        case invalidParameter
        case operationFailed
    }

    public enum NetworkError: Int { //BUFF: done
        case timeout = 2000
//        case authenticationFailed //uu
//        case connectionLost //uu
//        case connectionTerminated //UU
//        case connectionTimeout //uu
    }

    public enum CoreDataErrorCode: Int { //BUFF: done
        case couldNotInsertOrUpdate = 3000
//        case folderDoesNotExist //uu
//        case cannotStoreMessage //uu
//        case couldNotUpdateOrAddContact //uu
        case couldNotStoreFolder
//        case cannotFindAccountForEmail //uu
        case cannotFindAccount
        case cannotFindFolder
//        case cannotFindServerForAccount //uu
//        case cannotFindServer //uu
//        case cannotFindServerCredentials //UU
//        case cannotFindMessage //uu
//        case noImapConnectInfo //uu
//        case noFlags //uu
    }

    public enum SmtpErrorCode: Int { //BUFF: done
        case invalidConnection = 4000
        case messageNotSent
        case transactionInitiationFailed
        case recipientIdentificationFailed
        case transactionResetFailed
        case authenticationFailed
        case connectionLost
        case connectionTerminated //nUU
        case connectionTimedOut
        case requestCancelled
        case badResponse
    }

    /**
     Some errors shown to the user which are actually internal.
     */
    //BUFF: unused
//    public enum InternalErrorCode: Int {
//        case noModel = 5000
//    }

    /**
     Errors dealing with the pEp engine.
     */
    public enum PepErrorCode: Int { //BUFF: done
        case encryptionError = 6000
    }

    /**
     Errors dealing with IMAP.
     */
    public enum ImapErrorCode: Int { //BUFF: done
//        case unknownError = 7000 //uu
        case invalidConnection
//        case badResponseError //uu
//        case messageStoreFailed //uu
//        case folderCreateFailed //uu
//        case folderDeleteFailed //uu
//        case appendFailed //uu
//        case folderSyncFailed //uu
    }

//    static func errorIllegalState(_ component: String = #function, stateName: String) -> NSError {
//        let error = NSError.init(
//            domain: component, code: GeneralErrorCode.notImplemented.rawValue, //BUFF:  notImplemented for getting unexpected callback?
//            userInfo: [NSLocalizedDescriptionKey:
//                String.init(format: NSLocalizedString("Unexpected state: %@",
//                    comment: "General error description for operation that encountered an unexpected state/callback, e.g. a 'message received' when waiting for a list of folders"),
//                    stateName)])
//        return error
//    }
//
//    static func errorIllegalState(_ component: String = #function, errorMessage: String) -> NSError {
//        let error = NSError.init(
//            domain: component, code: GeneralErrorCode.notImplemented.rawValue,
//            userInfo: [NSLocalizedDescriptionKey: errorMessage])
//        return error
//    }

//    static func errorInvalidParameter(_ component: String = #function) -> NSError {
//        let error = NSError.init(
//            domain: component, code: GeneralErrorCode.invalidParameter.rawValue)
//        return error
//    }
//
//    static func errorInvalidParameter(_ component: String = #function, errorMessage: String) -> NSError {
//        let error = NSError.init(
//            domain: component, code: GeneralErrorCode.invalidParameter.rawValue,
//            userInfo: [NSLocalizedDescriptionKey: errorMessage])
//        return error
//    }

//    static func errorOperationFailed(_ component: String = #function, errorMessage: String) -> NSError {
//        let error = NSError.init(
//            domain: component, code: GeneralErrorCode.operationFailed.rawValue,
//            userInfo: [NSLocalizedDescriptionKey: errorMessage])
//        return error
//    }

//    static func errorFolderNotOpen(_ component: String = #function, folderName: String) -> NSError {
//        let error = NSError.init(
//            domain: component, code: GeneralErrorCode.illegalState.rawValue,
//            userInfo: [NSLocalizedDescriptionKey:
//                String.init(format: NSLocalizedString("Folder is not open: %@",
//                    comment: "General error description for operation that needs an open folder, but there was none"),
//                    folderName)])
//        return error
//    }

//    static func errorCouldNotStoreFolder(_ component: String = #function, name: String) -> NSError {
//        let error = NSError.init(
//            domain: component, code: CoreDataErrorCode.couldNotStoreFolder.rawValue,
//            userInfo: [NSLocalizedDescriptionKey:
//                String.init(format: NSLocalizedString("Cannot store folder: %@",
//                    comment: "Error description when not being able to store a folder"),
//                    name)])
//        return error
//    }

//    static func errorCannotFindAccount(component: String = #function) -> NSError {
//        let error = NSError.init(
//            domain: component, code: CoreDataErrorCode.cannotFindAccount.rawValue,
//            userInfo: [NSLocalizedDescriptionKey:
//                NSLocalizedString(
//                    "Cannot find/access account", comment:
//                    "Technical error description when not being able to fetch an account")])
//        return error
//    }

//    static func errorCannotFindFolder(component: String = #function) -> NSError {
//        let error = NSError.init(
//            domain: component, code: CoreDataErrorCode.cannotFindFolder.rawValue,
//            userInfo: [NSLocalizedDescriptionKey:
//                NSLocalizedString(
//                    "Cannot find folder from object ID", comment:
//                    "Technical error description when not being able to fetch a folder by object ID")])
//        return error
//    }

    //UU
//    static func errorTimeout(_ component: String = #function) -> NSError {
//        let error = NSError.init(
//            domain: component, code: NetworkError.timeout.rawValue,
//            userInfo: [NSLocalizedDescriptionKey:
//                NSLocalizedString("Timeout",
//                    comment: "General error description for a timeout")])
//        return error
//    }

//    static func errorSmtp(_ component: String = #function, code: SmtpErrorCode) -> NSError {
//        let error = NSError.init(
//            domain: component, code: code.rawValue,
//            userInfo: [NSLocalizedDescriptionKey:
//                String.init(format:
//                    NSLocalizedString("SMTP Error (%d)", comment: ""),
//                    code.rawValue)])
//        return error
//    }

//    //BUFF: used in PEPUtil?
//    static func errorEncryption(_ component: String = #function, status: PEP_STATUS) -> NSError {
//        let error = NSError.init(
//            domain: component, code: PepErrorCode.encryptionError.rawValue,
//            userInfo: [NSLocalizedDescriptionKey: String.init(format: NSLocalizedString(
//                "Could not encrypt message, pEp status: %d",
//                comment: "Error message when the engine failed to encrypt a message."),
//                status.rawValue)])
//        return error
//    }

//    static func errorSmtpInvalidConnection(component: String = #function) -> NSError {
//        let error = NSError.init(
//            domain: component, code: SmtpErrorCode.invalidConnection.rawValue,
//            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
//                "Invalid connection", comment: "used internally")])
//        return error
//    }

//    static func errorImapInvalidConnection(component: String = #function) -> NSError {
//        let error = NSError.init(
//            domain: component, code: ImapErrorCode.invalidConnection.rawValue,
//            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
//                "Invalid connection", comment: "used internally")])
//        return error
//    }
}
