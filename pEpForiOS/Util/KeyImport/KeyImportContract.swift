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

    /// Call after successfull handshake.
    /// Sends the private key without appending to "Sent" folder.
    func sendOwnPrivateKey(inAnswerToRequestMessage msg: Message)

    /// Call to inform the other device that we would love to start a Key Import session
    func sendInitKeyImportMessage(forAccount acccount: Account)

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    func sendHandshakeRequest(forAccount acccount: Account)

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
    /// Will be triggered when “pEp-key-import” detected, for p≡p key import.
    /// It informs the receiver about:
    /// 1) Another device wants to start a Key Import session with me (wants to import my key)
    /// 2) We received a handshake request
    ///
    /// - Parameter message: received import message
    func newKeyImportMessageArrived(message: Message)

    /// We received a private key in a green message.
    /// - Parameter account: account the private key has been sent to.
    func receivedPrivateKey(forAccount account: Account)

    /// Reports all errors.
    func errorOccurred(error: Error)
}
