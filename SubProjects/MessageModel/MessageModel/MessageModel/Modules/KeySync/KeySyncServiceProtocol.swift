//
//  KeySyncServiceProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

/// Responsible for handling all KeySync related tasks
protocol KeySyncServiceProtocol: ServiceProtocol {

    /// Creates a KeySyncService
    /// - Parameters:
    ///   - keySyncServiceHandshakeHandler: some one who takes responsibility for handling requests regarding
    ///                         handshakes.
    ///   - keySyncStateProvider: provides keysync en|disabled
    ///   - fastPollingDelegate: gets asked to poll as fast as possible when key sync protocol is running
    ///   - passphraseProvider: someone that can be asked for a passphrase (for a key)
    init(keySyncServiceHandshakeHandler: KeySyncServiceHandshakeHandlerProtocol?,
         keySyncStateProvider: KeySyncStateProvider,
         fastPollingDelegate: PollingDelegate?,
         passphraseProvider: PassphraseProviderProtocol,
         usePEPFolderProvider: UsePEPFolderProviderProtocol)
}
