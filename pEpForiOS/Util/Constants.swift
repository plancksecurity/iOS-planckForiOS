//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class Constants {
    public enum GeneralErrorCode: Int {
        case NotImplemented = 1000
    }

    public enum NetworkError: Int {
        case Timeout = 2000
        case AuthenticationFailed
        case ConnectionLost
        case ConnectionTerminated
    }

    public enum CoreDataErrorCode: Int {
        case CouldNotInsertOrUpdate = 3000
    }

    static func errorCouldNotInsertOrUpdate(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: CoreDataErrorCode.CouldNotInsertOrUpdate.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Could not insert or update object",
                    comment: "General error description when DB object could not be updated or inserted")])
        return error
    }

    static func errorNotImplemented(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: GeneralErrorCode.NotImplemented.rawValue,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Not implemented",
                    comment: "General error description for operation that is not yet implemented")])
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
}