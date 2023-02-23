//
//  KeySyncServiceHandshakeHandlerProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

public protocol KeySyncServiceHandshakeHandlerProtocol: AnyObject {

    /// Show pEp Sync Wizard
    ///
    /// - Parameters:
    ///   - keySyncHandshakeData: All the data needed for key sync
    ///   - completion: handle the possible results of type PEPSyncHandshakeResult
    func showHandshake(keySyncHandshakeData: KeySyncHandshakeData,
                       completion: ((KeySyncHandshakeResult)->())?)

    func cancelHandshake()

    func showSuccessfullyGrouped()

    func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())?)
}

public enum KeySyncErrorResponse {
    case tryAgain, notNow
}

/// Derived from engine/adapter enums.
public enum KeySyncHandshakeResult {
    /// PEPSyncHandshakeResultCancel, SYNC_HANDSHAKE_CANCEL
    case cancel

    /// PEPSyncHandshakeResultAccepted, SYNC_HANDSHAKE_ACCEPTED
    case accepted

    /// PEPSyncHandshakeResultRejected, SYNC_HANDSHAKE_REJECTED
    case rejected
}
