//
//  SmtpSendError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

//MB: - Revert changes

public enum SmtpSendError: Error {
    /**
     Received an unexpected callback.
     */
    case illegalState(FunctionName)

    case authenticationFailed(FunctionName, String, ServerErrorInfo?)
    case connectionLost(FunctionName, String?, ServerErrorInfo?)
    case connectionTerminated(FunctionName, ServerErrorInfo?)
    case connectionTimedOut(FunctionName, String?, ServerErrorInfo?)
    case badResponse(FunctionName, ServerErrorInfo?)

    /// Indicates a problem with the client certificate
    case clientCertificateNotAccepted
}

public struct ServerErrorInfo {
    public var port: String
    public var server: String
    public var connectionTransport: String
}
