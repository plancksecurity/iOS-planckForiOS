//
//  KeyImportService.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol KeyImportServiceProtocol: class {
    var delegate: KeyImportServiceDelegate? { get set }

    /// Call after successfull handshake.
    /// Sends the private key without appending to "Sent" folder.
    func sendOwnPrivateKey(inAnswerToRequestMessage msg: Message)

    /// Call to inform the other device that we would love to start a Key Import session
    func sendInitKeyImportMessage(forAccount acccount: Account)

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    func sendHandshakeRequest(forAccount acccount: Account)

    func setNewDefaultKey(for identity: Identity, fpr: String) throws
}

/// Called by background operation or NetworkService[Worker].
protocol KeyImportListenerProtocol {
    /// Will be triggered when “p≡p-key-import” detected, for p≡p key import.
    /// It informs the receiver about:
    /// 1) Another device wants to start a Key Import session with me (wants to import my key)
    /// 2) We received a handshake request
    ///
    /// - Parameter message: received import message
    func newKeyImportMessageArrived(message: Message)

    /// We received a private key in a green message.
    /// - Parameter account: account the private key has been sent to.
    func receivedPrivateKey(forAccount account: Account)
}

protocol KeyImportServiceDelegate: class, KeyImportListenerProtocol {
}

/// Instantiate in AppDelegate, keep in AppConfig (maybe in renamed MessageSyncService, not sure
/// yet), KeyImportListener will probably end up in NetworkService/ServiceConfig
class KeyImportService: KeyImportServiceProtocol {
    weak var delegate: KeyImportServiceDelegate?

    // MARK: - KeyImportServiceProtocol

    /// Call after successfull handshake.
    /// Sends the private key without appending to "Sent" folder.
    func sendOwnPrivateKey(inAnswerToRequestMessage msg: Message) {
        fatalError("Unimplemented stub")
    }

    /// Call to inform the other device that we would love to start a Key Import session
    func sendInitKeyImportMessage(forAccount acccount: Account) {
        //TODO: send unencrypted message to myself with header: "pEp-key-import: myPubKey_fpr"
        fatalError("Unimplemented stub")
    }

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    func sendHandshakeRequest(forAccount account: Account) {
        //TODO: send encrypted message to myself with header: "pEp-key-import: myPubKey_fpr"
        fatalError("Unimplemented stub")
    }

    func setNewDefaultKey(for identity: Identity, fpr: String) throws {
        try PEPSession().setOwnKey(identity.pEpIdentity(), fingerprint: fpr)
    }
}

// MARK: - KeyImportListenerProtocol

extension KeyImportService: KeyImportListenerProtocol {

    func newKeyImportMessageArrived(message: Message) {
        //We can ignore the key in the "pEp-key-import: partner_fpr" header. Simply forward
        delegate?.newKeyImportMessageArrived(message: message)
    }

    func receivedPrivateKey(forAccount account: Account) {
        delegate?.receivedPrivateKey(forAccount: account)
    }
}
