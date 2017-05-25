//
//  ImapSyncError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

enum ImapSyncError: Error {
    /**
     Received an unexpected callback.
     */
    case illegalState(FunctionName)

    case authenticationFailed(FunctionName)
    case connectionLost(FunctionName)
    case connectionTerminated(FunctionName)
    case connectionTimedOut(FunctionName)
    case actionFailed(Error)
}
