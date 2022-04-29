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

    case authenticationFailed(FunctionName, String, String?)
    case connectionLost(FunctionName, String?, String?)
    case connectionTerminated(FunctionName, String?)
    case connectionTimedOut(FunctionName, String?, String?)
    case badResponse(FunctionName, String?)

    /// Indicates a problem with the client certificate
    case clientCertificateNotAccepted
}
