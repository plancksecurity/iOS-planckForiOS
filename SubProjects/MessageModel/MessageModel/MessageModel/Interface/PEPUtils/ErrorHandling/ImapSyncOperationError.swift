//
//  ImapSyncOperationError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

public enum ImapSyncOperationError: Error, Equatable {
    /**
     Received an unexpected callback.
     */
    case illegalState(FunctionName)
    case authenticationFailed(FunctionName, String)
    case authenticationFailedXOAuth2(FunctionName, String)
    case connectionLost(FunctionName)
    case connectionTerminated(FunctionName)
    case connectionTimedOut(FunctionName)
    case folderAppendFailed
    case badResponse(String?)
    case actionFailed

    /// Indicates a problem with the client certificate
    case clientCertificateNotAccepted
}
