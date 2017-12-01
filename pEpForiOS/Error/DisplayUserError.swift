//
//  DisplayUserError.swift
//  pEp
//
//  Created by Andreas Buff on 30.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Error to display to the user.
/// The multiple errors reported from different layers can and should be clustered here to not
/// overwhelm the user with internals.
struct DisplayUserError {
    enum ErrorType {
        case authenticationFailed
        case internalError
        case brokenServerConnection
        case unknownError
    }
    /// Description taken over from errors we do not know and thus can not classify
    private var foreignDescription: String?

    /// The type of the DisplayUserError. Meant to give clients the chance to handle different
    /// errors differentelly or even ignore certain types.
    let type:ErrorType

    init(withError error: Error) {
        if let smtpError = error as? SmtpSendError {
            type = DisplayUserError.type(forError: smtpError)
        } else if let imapError = error as? ImapSyncError {
            type = DisplayUserError.type(forError: imapError)
        } else {
            foreignDescription = error.localizedDescription
            type = .unknownError
        }
    }

    public var title: String? {
        switch type {
        case .authenticationFailed:
            return NSLocalizedString("Login Failed",
                                     comment:
                """
Title of error alert shown to the user in case the authentication to IMAP or SMTP server failed.
""")
        case .brokenServerConnection:
            return NSLocalizedString("Server Unreachable)",
                                     comment:
                "Title of error alert shown to the user in case we can not connect to the server")
        case .internalError:
            return NSLocalizedString("Internal Error",
                                     comment:
                """
Title of error alert shown to the user in case an error in the app occured that is not caused or
related to the server
""")
        case .unknownError:
            // We have an error that is not known to us.
            // All we can do is pass its description.
            return NSLocalizedString("Error",
                                     comment:
                "Title of error alert shown to the user in case an unknown error occured.")
        }
    }

    public var errorDescription: String? {
        switch type {
        case .authenticationFailed:
            return NSLocalizedString("It was impossible to login to the server.",
                                     comment:
                """
Error message shown to the user in case the authentication to IMAP or SMTP server failed.
""")
        case .brokenServerConnection:
            return NSLocalizedString("We could not connect to the server.)",
                                     comment:
                "Error message shown to the user in case we can not connect to the server")
        case .internalError:
            return NSLocalizedString("An internal error occured. Sorry, that should not happen.",
                                     comment:
                """
Error message shown to the user in case an error in the app occured that is not caused or
related to the server
""")
        case .unknownError:
            // We have an error that is not known to us.
            // All we can do is pass its description.
            return foreignDescription
        }
    }

    static private func type(forError error: SmtpSendError) -> ErrorType {
        switch error {
        case .illegalState:
            return .internalError
        case .authenticationFailed:
            return .authenticationFailed
        case .connectionLost:
            return .brokenServerConnection
        case .connectionTerminated:
            return .brokenServerConnection
        case .connectionTimedOut:
            return .brokenServerConnection
        case .badResponse:
            return .internalError
        }
    }

    static private func type(forError error: ImapSyncError) -> ErrorType {
        switch error {
        case .illegalState:
            return .internalError
        case .authenticationFailed:
            return .authenticationFailed
        case .connectionLost:
            return .brokenServerConnection
        case .connectionTerminated:
            return .brokenServerConnection
        case .connectionTimedOut:
            return .brokenServerConnection
        case .folderAppendFailed:
            return .internalError
        case .badResponse:
            return .internalError
        case .actionFailed:
            return .internalError
        }
    }
}
