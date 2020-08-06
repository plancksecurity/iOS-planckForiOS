//
//  KeySyncServiceHandshakeHandlerProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

public protocol KeySyncServiceHandshakeHandlerProtocol: class {

    /// Show pEp Sync Wizzard
    ///
    /// - Parameters:
    ///   - me: my trust words
    ///   - partner: my partner trust words
    ///   - isNewGroup: is it a new group creation or i am joining an existing group
    ///   - completion: handle the possible results of type PEPSyncHandshakeResult
    func showHandshake(meFingerprint: String?,
                       partnerFingerprint: String?,
                       isNewGroup: Bool,
                       completion: ((KeySyncHandshakeResult)->())?)

    func cancelHandshake()

    func showSuccessfullyGrouped()

    func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())?)
}

public enum KeySyncErrorResponse {
    case tryAgain, notNow
}

public enum KeySyncHandshakeResult {
    /// PEPSyncHandshakeResultCancel, SYNC_HANDSHAKE_CANCEL, -1
    case cancel

    /// PEPSyncHandshakeResultAccepted, SYNC_HANDSHAKE_ACCEPTED, 0
    case accepted

    /// PEPSyncHandshakeResultRejected, SYNC_HANDSHAKE_REJECTED, 1
    case rejected
}
