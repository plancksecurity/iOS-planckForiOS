//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class Constants {
    public enum ErrorCode: Int {
        case NotImplemented = 1000
    }

    public enum NetworkError: Int {
        case Timeout = 2000
        case AuthenticationFailed
        case ConnectionLost
        case ConnectionTerminated
    }

    static func errorNotImplemented(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ErrorCode.NotImplemented.rawValue,
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