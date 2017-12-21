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
//
/// We might want to add a .ignore type to ErrorType to be able to not show certain errors to
// the user at all.
//
/// As errors are most likely shown to the user in some alert-like view, it offers a title and
/// a message.
/// Buttons and actions to react to buttons have intentionally not been implemented. Currently not
/// required.
struct DisplayUserError: LocalizedError {
    enum ErrorType {
        /// We could not login for some reason
        case authenticationFailed
        /// We could not send a mesage for some reason
        case messageNotSent
        /// Somthing went wrong internally. Do not bother the user with technical details
        case internalError
        /// Any issue comunicating with the server
        case brokenServerConnection
        /// Use this only for errors that are not known and thus can not be categorized in a
        /// DisplayUserError
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

    // MARK: - Cluster Errors

    // MARK: SmtpSendError

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

    // MARK: ImapSyncError

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

    // MARK: BackgroundError.GeneralError

    static private func type(forError error: BackgroundError.GeneralError) -> ErrorType {
        switch error {
        case .illegalState:
            return .internalError
        case .invalidParameter:
            return .internalError
        case .operationFailed:
            return .internalError
        }
    }

    // MARK: BackgroundError.ImapError

    static private func type(forError error: BackgroundError.ImapError) -> ErrorType {
        switch error {
        case .invalidConnection:
            return .brokenServerConnection
        }
    }

    // MARK: BackgroundError.SmtpError

    static private func type(forError error: BackgroundError.SmtpError) -> ErrorType {
        switch error {
        case .invalidConnection:
            return .brokenServerConnection
        case .messageNotSent:
            return .messageNotSent
        case .transactionInitiationFailed:
            return .brokenServerConnection
        case .recipientIdentificationFailed:
            return .brokenServerConnection
        case .transactionResetFailed:
            return .brokenServerConnection
        case .authenticationFailed:
            return .authenticationFailed
        case .connectionLost:
            return .brokenServerConnection
        case .connectionTerminated:
            return .brokenServerConnection
        case .connectionTimedOut:
            return .brokenServerConnection
        case .requestCancelled:
            return .brokenServerConnection
        case .badResponse:
            return .internalError
        }
    }

    // MARK: BackgroundError.CoreDataError

    static private func type(forError error: BackgroundError.CoreDataError) -> ErrorType {
        switch error {
        case .couldNotInsertOrUpdate:
            return .internalError
        case .couldNotStoreFolder:
            return .internalError
        case .couldNotStoreMessage:
            return .internalError
        case .couldNotFindAccount:
            return .internalError
        case .couldNotFindFolder:
            return .internalError
        case .couldNotFindMessage:
            return .internalError
        }
    }

    // MARK: BackgroundError.PepError

    static private func type(forError error: BackgroundError.PepError) -> ErrorType {
        switch error {
        case .encryptionError:
            return .internalError
        }
    }

    // MARK: - Title & Message

    public var title: String? {
        switch type {
        case .authenticationFailed:
            return NSLocalizedString("Login Failed",
                                     comment:
                """
Title of error alert shown to the user in case the authentication to IMAP or SMTP server failed.
""")
        case .messageNotSent:
            return NSLocalizedString("Error",
                                     comment:
                """
Title of error alert shown to the user in case a message could not be sent
""")
        case .brokenServerConnection:
            return NSLocalizedString("Server Unreachable",
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
        case .messageNotSent:
            return NSLocalizedString("The message could not be sent. Please try again later.",
                                     comment:
                """
Error message shown to the user in case a message could not be sent.
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
}
