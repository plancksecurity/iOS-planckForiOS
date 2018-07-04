//
//  KeyImportService.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
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

    func setNewDefaultKey(for identity: Identity, fpr: String) throws
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
}

/// Instantiate in AppDelegate, keep in AppConfig (maybe in renamed MessageSyncService, not sure
/// yet), KeyImportListener will probably end up in NetworkService/ServiceConfig
public class KeyImportService {
    public weak var delegate: KeyImportServiceDelegate?

    // MARK: - Working bees

    enum Header: String {
        case pEpKeyImport = "pEp-key-import"
    }

    private func isKeyImportMessage(message: Message) -> Bool {
        return message.optionalFields[Header.pEpKeyImport.rawValue] != nil
    }

    private func isPrivateKeyMessage(message: Message, flags: PEP_decrypt_flags) -> Bool {
        return flags.rawValue & PEP_decrypt_flag_own_private_key.rawValue == 1
    }
}

// MARK: - KeyImportServiceProtocol

extension KeyImportService: KeyImportServiceProtocol {
    /// Call after successfull handshake.
    public func sendOwnPrivateKey(inAnswerToRequestMessage msg: Message) {
        /// TODO: Send the private key without appending to "Sent" folder.
        fatalError("Unimplemented stub")
    }

    /// Call to inform the other device that we would love to start a Key Import session
    public func sendInitKeyImportMessage(forAccount acccount: Account) {
        //TODO: send unencrypted message to myself with header: "pEp-key-import: myPubKey_fpr" (assume: without appending to sent folder)
        fatalError("Unimplemented stub")
    }

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    public func sendHandshakeRequest(forAccount account: Account) {
        //TODO: send encrypted message to myself with header: "pEp-key-import: myPubKey_fpr"
        fatalError("Unimplemented stub")
    }

    public func setNewDefaultKey(for identity: Identity, fpr: String) throws {
        try PEPSession().setOwnKey(identity.pEpIdentity(), fingerprint: fpr)
    }
}

// MARK: - KeyImportListenerProtocol

extension KeyImportService: KeyImportListenerProtocol {
    public func handleKeyImport(forMessage msg: Message, flags: PEP_decrypt_flags) -> Bool {
        var weTakeOver = false
        if isKeyImportMessage(message: msg) {
            delegate?.newKeyImportMessageArrived(message: msg)
            weTakeOver = true
        } else if isPrivateKeyMessage(message: msg, flags: flags) {
            delegate?.receivedPrivateKey(forAccount: msg.parent.account)
            weTakeOver = true
        }
        return weTakeOver
    }
}
