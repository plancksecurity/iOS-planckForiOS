//
//  Notification+KeySyncState.swift
//  MessageModel
//
//  Created by Andreas Buff on 20.11.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

// MARK: - Notification+KeySyncState

extension Notification.Name {

    /// Notification name for KeySync key sync state changed by engine broadcasts.
    static public let pEpKeySyncDisabledByEngine =
        Notification.Name("security.pEp.pEpKeySyncDisabledByEngine")
}
