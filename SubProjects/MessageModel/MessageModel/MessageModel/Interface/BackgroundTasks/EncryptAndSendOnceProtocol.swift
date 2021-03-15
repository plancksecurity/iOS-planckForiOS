//
//  EncryptAndSendOnceProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 11.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

/// Enables to send out all outstanding mails,
/// get informed about errors, when work is finished,
/// and be able to cancel on request.
public protocol EncryptAndSendOnceProtocol {
    /// Sends out all outstanding mails, informing the delegate
    /// about success or errors.
    /// - parameter completion: Completion block for sending outstanding mails.
    /// If `error` is nil, then all messages have been successfully sent.
    /// Otherwise, an error occurred with at least one message.
    func sendAllOutstandingMessages(completion: @escaping (_ error: Error?) -> ())

    /// Cancels any current sending going on,
    /// triggered by `sendAllOutstandingMessages`.
    /// No-op if there is currently no sending of mails taking place.
    func cancel()
}
