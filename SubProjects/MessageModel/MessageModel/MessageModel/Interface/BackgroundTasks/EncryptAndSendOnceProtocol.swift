//
//  EncryptAndSendOnceProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 11.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol EncryptAndSendOnceProtocol {
    /// Triggers a one-time send of all outgoing messages,
    /// on all accounts,
    /// triggered by a request of the sharing extension to do so,
    /// via a defined task in the set of
    /// BGTaskSchedulerPermittedIdentifiers.
    func sendAll()
}
