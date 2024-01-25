//
//  BackgroundError.swift
//  pEp
//
//  Created by Andreas Buff on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Wraps all errors that might occur in Background/Service layer
public struct BackgroundError {

    public enum GeneralError: Error {
        /// Unexpected state.
        /// Examples are:
        /// An operation that encountered an unexpected state/callback, e.g. a 'message received'
        /// when waiting for a list of folders
        /// or
        /// An operation that needs an open folder, but there was none
        case illegalState(info: String?)
        case invalidParameter(info: String?)
        case operationFailed(info: String?)

        public func info() -> String? {
            switch self {
            case .illegalState(let info):
                return info
            case .invalidParameter(let info):
                return info
            case .operationFailed(let info):
                return info
            }
        }
    }

    public enum ImapError: Error {
        case invalidConnection(info: String?)
        case invalidAccount

        public func info() -> String? {
            switch self {
            case .invalidConnection(let info):
                return info
            case .invalidAccount:
                return nil
            }
        }
    }

    public enum SmtpError: Error {
        case invalidConnection(info: String?)
        case messageNotSent(info: String?)
        case transactionInitiationFailed(info: String?)
        case recipientIdentificationFailed(info: String?)
        case transactionResetFailed(info: String?)
        case authenticationFailed(info: String?)
        case connectionLost(info: String?)
        case connectionTerminated(info: String?)
        case connectionTimedOut(info: String?)
        case requestCancelled(info: String?)
        case badResponse(info: String?)
        case invalidAccount

        public func info() -> String? {
            switch self {
            case .invalidConnection(let info):
                return info
            case .messageNotSent(let info):
                return info
            case .transactionInitiationFailed(let info):
                return info
            case .recipientIdentificationFailed(let info):
                return info
            case .transactionResetFailed(let info):
                return info
            case .authenticationFailed(let info):
                return info
            case .connectionLost(let info):
                return info
            case .connectionTerminated(let info):
                return info
            case .connectionTimedOut(let info):
                return info
            case .requestCancelled(let info):
                return info
            case .badResponse(let info):
                return info
            case .invalidAccount:
                return nil
            }
        }
    }

    public enum CoreDataError: Error {
        case couldNotInsertOrUpdate(info: String?)
        case couldNotStoreMessage(info: String?)
        case couldNotFindAccount(info: String?)
        case couldNotFindFolder(info: String?)
        case couldNotFindMessage(info: String?)
        
        public func info() -> String? {
            switch self {
            case .couldNotInsertOrUpdate(let info):
                return info
            case .couldNotStoreMessage(let info):
                return info
            case .couldNotFindAccount(let info):
                return info
            case .couldNotFindFolder(let info):
                return info
            case .couldNotFindMessage(let info):
                return info
            }
        }
    }

    /**
     Errors dealing with the pEp engine.
     */
    public enum PepError: Error {
        case passphraseRequired(info: String?)
        case wrongPassphrase(info: String?)

        public func info() -> String? {
            switch self {
            case .passphraseRequired(info: let info):
                return info
            case .wrongPassphrase(info: let info):
                return info
            }
        }
    }
}
