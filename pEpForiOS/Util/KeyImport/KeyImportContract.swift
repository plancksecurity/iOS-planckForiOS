//
//  KeyImportContract.swift
//  pEp
//
//  Created by Andreas Buff on 04.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

public protocol KeyImportServiceProtocol: class {
    var delegate: KeyImportServiceDelegate? { get set }

    /// Call to inform the other device that we would love to start a Key Import session.
    /// - Parameters:
    ///   - acccount: account to send message from
    func sendInitKeyImportMessage(forAccount acccount: Account)

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    ///
    /// - Parameters:
    ///   - acccount: account to send message from
    ///   - fpr: key to encrypt message with
    func sendHandshakeRequest(forAccount account: Account, fpr: String)

    /// Call after successfull handshake.
    /// Sends the private key without appending to "Sent" folder.
    /// - Parameters:
    ///   - acccount: account to send message from
    ///   - fpr: key to encrypt message with
    func sendOwnPrivateKey(forAccount acccount: Account, fpr: String)

    func setNewDefaultKey(for identity: Identity, fpr: String)
}

/// Called by background operation or NetworkService[Worker].
public protocol KeyImportListenerProtocol {
    /// Figures out wheter or not the given message has been sent as part of the KeyImport protocol.
    /// This is:
    /// - An initial "I want to import your key" message from another device
    /// - A handshake request for a running key import session
    /// - A private key to import has been send by the other device
    ///
    /// - Parameter msg: message to evaluate
    /// - Returns:  true if the message is part of the Key Import protocol.
    ///             false otherwize
    func handleKeyImport(forMessage msg: Message, flags: PEP_decrypt_flags) -> Bool
}

public protocol KeyImportServiceDelegate: class {
    /// It informs the receiver that another device wants to start a Key Import session with
    /// me (wants to import my key).
    ///
    /// Will be triggered when a message is received that:
    /// - has the FPR of a foreign (not mine) key defined in "pEp-key-import" header
    /// - is unencrypted (PEP_color == grey)
    /// - is in Inbox
    /// - Parameters:
    ///   - account: account the key import request has been sent for
    ///   - fpr: fingerprint of senders public key (from "pEp-key-import" header)
    func newInitKeyImportRequestMessageArrived(forAccount account: Account, fpr: String)

    /// It informs the receiver that the other device is ready for handshake
    ///
    /// Will be triggered when a message is received that:
    /// - has the FPR of a foreign (not mine) key defined in "pEp-key-import" header
    /// - is encrypted
    /// - PEP_color == yellow
    /// - is in Inbox
    /// - Parameters:
    ///   - account: account the key import request has been sent for
    ///   - fpr: fingerprint of senders public key (from "pEp-key-import" header)
    func newHandshakeRequestMessageArrived(forAccount account: Account, fpr: String)

    /// We received a private key in a green message.
    /// - Parameter account: account the private key has been sent to.
    func receivedPrivateKey(forAccount account: Account)

    /// Reports all errors.
    func errorOccurred(error: Error)
}
