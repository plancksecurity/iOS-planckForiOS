//
//  SmtpSendError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

enum SmtpSendError: Error {
    /**
     Received an unexpected callback.
     */
    case illegalState(FunctionName)

    case authenticationFailed(FunctionName, String)
    case connectionLost(FunctionName)
    case connectionTerminated(FunctionName)
    case connectionTimedOut(FunctionName)
    case badResponse(FunctionName)
}

extension SmtpSendError: Equatable {
    public static func ==(lhs: SmtpSendError, rhs: SmtpSendError) -> Bool {
        switch (lhs, rhs) {
        case (.illegalState(let fn1), .illegalState(let fn2)):
            return fn1 == fn2
        case (.authenticationFailed(let fn1), .authenticationFailed(let fn2)):
            return fn1 == fn2
        case (.connectionLost(let fn1), .connectionLost(let fn2)):
            return fn1 == fn2
        case (.connectionTerminated(let fn1), .connectionTerminated(let fn2)):
            return fn1 == fn2
        case (.connectionTimedOut(let fn1), .connectionTimedOut(let fn2)):
            return fn1 == fn2
        case (.badResponse(let fn1), .badResponse(let fn2)):
            return fn1 == fn2
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
        case (.badResponse, _):
            return false
        }
    }
}
