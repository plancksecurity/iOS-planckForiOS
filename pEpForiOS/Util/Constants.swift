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

    public enum GeneralErrorCode: Int {
        case NotImplemented = 1000
        case IllegalState
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
                NSString.init(format: NSLocalizedString("Unexpected state: %@",
                    comment: "General error description for operation that encountered an unexpected state/callback, e.g. a 'message received' when waiting for a list of folders"),
                    stateName)])
        return error
    }

    static func errorFolderDoesNotExist(component: String,
                                                     folderName: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.FolderDoesNotExist.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSString.init(format: NSLocalizedString("Cannot store mail for non-existent folder: %@",
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
                NSString.init(format: NSLocalizedString("Cannot store contact: %@",
                    comment: "Error description when not being able to update or store a contact"),
                    name)])
        return error
    }

    static func errorCouldNotStoreFolder(component: String, name: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.CouldNotStoreFolder.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSString.init(format: NSLocalizedString("Cannot store folder: %@",
                    comment: "Error description when not being able to store a folder"),
                    name)])
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
}