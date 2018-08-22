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
///
/// We might want to add a .ignore type to ErrorType to be able to not show certain errors to
/// the user at all.
///
/// As errors are most likely shown to the user in some alert-like view, it offers a title and
/// a message.
/// Buttons and actions to react to buttons have intentionally not been implemented. Currently not
/// required.
struct DisplayUserError: LocalizedError { //IOS-1248: handle LoginTableViewControllerError
    enum ErrorType {
        /// We could not login for some reason
        case authenticationFailed
        /// We could not send a message for some reason
        case messageNotSent
        /// Somthing went wrong internally. Do not bother the user with technical details.
        case internalError
        /// Any issue comunicating with the server
        case brokenServerConnectionImap //IOS-1248: differ between IMAP and SMTP
        /// Any issue comunicating with the server
        case brokenServerConnectionSmtp
        /// Use this only for errors that are not known to DisplayUserError yet and thus can not
        /// be categorized
        case unknownError

        /// Whether or not an error of this type is supposed to be shown to the user.
        var shouldBeShownToUser: Bool {
            switch self {
            case .internalError:
                #if DEBUG
                    return true
                #else
                    return false
                #endif
            case .authenticationFailed,
                 .brokenServerConnectionImap,
                 .brokenServerConnectionSmtp,
                 .messageNotSent,
                 .unknownError:
                return true
            }
        }
    }
    /// Description taken over from errors we do not know and thus can not classify
    private var foreignDescription: String?

    /// The type of the DisplayUserError. Meant to give clients the chance to handle different
    /// errors differentelly or even ignore certain types.
    let type:ErrorType

    /// Creates a user friendly error to present in an alert or such. I case the error type is not
    /// suitable to display to the user (should fail silently), nil is returned.
    ///
    /// - Parameter error: error to create a DisplayUserError for
    /// - Returns:  nil if you should not bother the user with this kind of error,
    ///             user friendly error otherwize.
    init?(withError error: Error) {
        if let displayUserError = error as? DisplayUserError {
            self = displayUserError
        } else if let smtpError = error as? SmtpSendError {
            type = DisplayUserError.type(forError: smtpError)
        } else if let imapError = error as? ImapSyncError {
            type = DisplayUserError.type(forError: imapError)
        } else if let oauthInternalError = error as? OAuth2AuthViewModelError {
            type = DisplayUserError.type(forError: oauthInternalError)
        } else if let oauthError = error as? OAuth2AuthorizationError {
            type = DisplayUserError.type(forError: oauthError)
        }
            //BackgroundError
        else if let err = error as? BackgroundError.GeneralError {
            type = DisplayUserError.type(forError: err)
        } else if let err = error as? BackgroundError.ImapError {
            type = DisplayUserError.type(forError: err)
        } else if let err = error as? BackgroundError.SmtpError {
            type = DisplayUserError.type(forError: err)
        } else if let err = error as? BackgroundError.CoreDataError {
            type = DisplayUserError.type(forError: err)
        }else if let err = error as? BackgroundError.PepError {
            type = DisplayUserError.type(forError: err)
        }
            //Unknown
        else {
            foreignDescription = error.localizedDescription
            type = .unknownError
        }

        if !type.shouldBeShownToUser {
            return nil
        }
    }

    // MARK: - CLUSTER ERRORS

    // MARK: SmtpSendError

    static private func type(forError error: SmtpSendError) -> ErrorType {
        switch error {
        case .illegalState:
            return .internalError
        case .authenticationFailed:
            return .authenticationFailed
        case .connectionLost:
            return .brokenServerConnectionSmtp
        case .connectionTerminated:
            return .brokenServerConnectionSmtp
        case .connectionTimedOut:
            return .brokenServerConnectionSmtp
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
            return .brokenServerConnectionImap
        case .connectionTerminated:
            return .brokenServerConnectionImap
        case .connectionTimedOut:
            return .brokenServerConnectionImap
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
            return .brokenServerConnectionImap
        }
    }

    // MARK: BackgroundError.SmtpError

    static private func type(forError error: BackgroundError.SmtpError) -> ErrorType {
        switch error {
        case .invalidConnection:
            return .brokenServerConnectionSmtp
        case .messageNotSent:
            return .messageNotSent
        case .transactionInitiationFailed:
            return .brokenServerConnectionSmtp
        case .recipientIdentificationFailed:
            return .brokenServerConnectionSmtp
        case .transactionResetFailed:
            return .brokenServerConnectionSmtp
        case .authenticationFailed:
            return .authenticationFailed
        case .connectionLost:
            return .brokenServerConnectionSmtp
        case .connectionTerminated:
            return .brokenServerConnectionSmtp
        case .connectionTimedOut:
            return .brokenServerConnectionSmtp
        case .requestCancelled:
            return .brokenServerConnectionSmtp
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

    // MARK: OAuth2InternalError

    static private func type(forError error: OAuth2AuthViewModelError) -> ErrorType {
        // All OAuth2InternalErrors are internal errors.
        switch error {
        default:
            return .internalError
        }
    }

    // MARK: OAuth2AuthorizationError

    static private func type(forError error: OAuth2AuthorizationError) -> ErrorType {
        switch error {
        case .inconsistentAuthorizationResult:
            return .authenticationFailed
        }
    }

    // MARK: - TITLE & MESSAGE

    public var title: String? {
        switch type {
        case .authenticationFailed:
            return NSLocalizedString("Login Failed",
                                     comment:
                "Title of error alert shown to the user in case the authentication to IMAP or SMTP server failed.")
        case .messageNotSent:
            return NSLocalizedString("Error",
                                     comment:
                "Title of error alert shown to the user in case a message could not be sent")
        case .brokenServerConnectionImap:
            return NSLocalizedString("Server Unreachable",
                                     comment:
                "Title of error alert shown to the user in case we can not connect to the IMAP server")
        case .brokenServerConnectionSmtp:
            return NSLocalizedString("Server Unreachable",
                                     comment:
                "Title of error alert shown to the user in case we can not connect to the SMTP server")
        case .internalError:
            return NSLocalizedString("Internal Error",
                                     comment:"Title of error alert shown to the user in case an error in the app occured that is not caused or related to the server ")
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
            return NSLocalizedString("It was impossible to login to the server. Username or password are wrong.",
                                     comment:
                "Error message shown to the user in case the authentication to IMAP or SMTP server failed.")
        case .messageNotSent:
            return NSLocalizedString("The message could not be sent. Please try again later.",
                                     comment:
                "Error message shown to the user in case a message could not be sent.")
        case .brokenServerConnectionImap:
            return NSLocalizedString("We could not connect to the IMAP server.",
                                     comment:
                "Error message shown to the user in case we can not connect to the IMAP server")
        case .brokenServerConnectionSmtp:
            return NSLocalizedString("We could not connect to the SMTP server.",
                                     comment:
                "Error message shown to the user in case we can not connect to the SMTP server")
        case .internalError:
            return NSLocalizedString("An internal error occured. Sorry, that should not happen.",
                                     comment:
                "Error message shown to the user in case an error in the app occured that is not caused or related to the server")
        case .unknownError:
            // We have an error that is not known to us.
            // All we can do is pass its description.
            return foreignDescription
        }
    }
}
