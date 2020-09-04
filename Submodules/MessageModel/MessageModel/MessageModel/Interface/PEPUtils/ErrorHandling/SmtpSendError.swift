//
//  SmtpSendError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

public enum SmtpSendError: Error {
    /**
     Received an unexpected callback.
     */
    case illegalState(FunctionName)

    case authenticationFailed(FunctionName, String)
    case connectionLost(FunctionName)
    case connectionTerminated(FunctionName)
    case connectionTimedOut(FunctionName)
    case badResponse(FunctionName)

    /// Indicates a problem with the client certificate
    case clientCertificateNotAccepted
}
