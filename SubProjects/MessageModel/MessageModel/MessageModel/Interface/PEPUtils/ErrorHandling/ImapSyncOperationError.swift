//
//  ImapSyncOperationError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

public enum ImapSyncOperationError: Error {
    /**
     Received an unexpected callback.
     */
    case illegalState(FunctionName)
    case authenticationFailed(FunctionName, String)
    case connectionLost(FunctionName)
    case connectionTerminated(FunctionName)
    case connectionTimedOut(FunctionName)
    case folderAppendFailed
    case badResponse(String?)
    case actionFailed

    /// Indicates a problem with the client certificate
    case clientCertificateNotAccepted
}

extension ImapSyncOperationError: Equatable {
    public static func ==(lhs: ImapSyncOperationError, rhs: ImapSyncOperationError) -> Bool {
        switch (lhs, rhs) {
        case (.illegalState(let fn1), .illegalState(let fn2)):
            return fn1 == fn2
        case (.authenticationFailed(let fn1, let account1), .authenticationFailed(let fn2, let account2)):
            let sameAccount = account1 == account2
            let sameFunctionName = fn1 == fn2
            return sameAccount && sameFunctionName
        case (.connectionLost(let fn1), .connectionLost(let fn2)):
            return fn1 == fn2
        case (.connectionTerminated(let fn1), .connectionTerminated(let fn2)):
            return fn1 == fn2
        case (.connectionTimedOut(let fn1), .connectionTimedOut(let fn2)):
            return fn1 == fn2
        case (.folderAppendFailed, .folderAppendFailed):
            return true
        case (.badResponse(let s1), .badResponse(let s2)):
            return s1 == s2
        case (.actionFailed, .actionFailed):
            return true
        case (.clientCertificateNotAccepted, .clientCertificateNotAccepted):
            return true
        case (.illegalState, _):
            return false
        case (.authenticationFailed, _):
            return false
        case (.connectionLost, _):
            return false
        case (.connectionTerminated, _):
            return false
        case (.connectionTimedOut, _):
            return false
        case (.folderAppendFailed, _):
            return false
        case (.badResponse, _):
            return false
        case (.actionFailed, _):
            return false
        case (.clientCertificateNotAccepted, _):
            return false
        }
    }
}
