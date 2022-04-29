//
//  SmtpConnectionProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 31.01.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework

/// Wraps the Pantomime SMTP API.
/// You MUST use this to place SMTP ralated calls to Pantomime.
/// Conform to ImapSyncDelegate to get SMTP realated Pantomime delegate calls.
protocol SmtpConnectionProtocol {
    var delegate: SmtpConnectionDelegate? { get set }

    func start()

    func setRecipients(_ recipients: [Any]?)

    func setMessageData(_ data: Data?)

    func setMessage(_ message: CWMessage)

    func sendMessage()

    var accountAddress: String { get }

    /// Indicates if a client certificate was set for this connection.
    var isClientCertificateSet: Bool { get }

    var displayInfo: String { get }
}
