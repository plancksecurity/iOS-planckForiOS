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
    ///   - identityMe: own identity
    ///   - identityPartner: a partner identity
    ///   - isNewGroup: is it a new group creation or i am joining an existing group
    ///   - completion: handle the possible results of type PEPSyncHandshakeResult
    func showHandshake(identityMe: Identity?,
                       identityPartner: Identity?,
                       isNewGroup: Bool,
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
