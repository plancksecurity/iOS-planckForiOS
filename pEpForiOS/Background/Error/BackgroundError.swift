//
//  BackgroundError.swift
//  pEp
//
//  Created by Andreas Buff on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

struct BackgroundError {

public enum BackgroundGeneralError: Error {
    //        case notImplemented(info: String?) //UU?
    case illegalState(info: String?)
    case invalidParameter(info: String?)
    case operationFailed(info: String?)
}

public enum BackgroundNetworkError: Error {
    case timeout(info: String?)
}

public enum BackgroundSmtpError: Error {
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

public enum BackgroundCoreDataError: Error {
    case couldNotInsertOrUpdate(info: String?)
    case couldNotStoreFolder(info: String?)
    case cannotFindAccount(info: String?)
    case cannotFindFolder(info: String?)
}

/**
 Errors dealing with the pEp engine.
 */
public enum BackgroundCorePepError: Error {
    case encryptionError(info: String?)
}

/**
 Errors dealing with IMAP.
 */
public enum BackgroundImapError: Error {
    case invalidConnection(info: String?)
}
}
