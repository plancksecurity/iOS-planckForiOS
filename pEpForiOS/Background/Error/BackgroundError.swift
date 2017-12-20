//
//  BackgroundError.swift
//  pEp
//
//  Created by Andreas Buff on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

struct BackgroundError {

    public enum GeneralError: Error {
        //        case notImplemented(info: String?) //UU?
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

    public enum NetworkError: Error {
        case timeout(info: String?)
        public func info() -> String? {
            switch self {
            case .timeout(let info):
                return info
            }
        }
    }

    /**
     Errors dealing with IMAP.
     */
    public enum ImapError: Error {
        case invalidConnection(info: String?)

        public func info() -> String? {
            switch self {
            case .invalidConnection(let info):
                return info
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
            }
        }
    }

    public enum CoreDataError: Error {
        case couldNotInsertOrUpdate(info: String?)
        case couldNotStoreFolder(info: String?)
        case couldNotFindAccount(info: String?)
        case couldNotFindFolder(info: String?)
        case couldNotFindMessage(info: String?)
        
        public func info() -> String? {
            switch self {
            case .couldNotInsertOrUpdate(let info):
                return info
            case .couldNotStoreFolder(let info):
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
    public enum CorePepError: Error {
        case encryptionError(info: String?)

        public func info() -> String? {
            switch self {
            case .encryptionError(let info):
                return info
            }
        }
    }
}
