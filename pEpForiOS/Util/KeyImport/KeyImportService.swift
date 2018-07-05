//
//  KeyImportService.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class KeyImportService {
    public weak var delegate: KeyImportServiceDelegate?

    /// Specifies how long a key import message is valid
    static let ttlKeyImportMessages: TimeInterval = 5 * 60 //IOS-1028: timeout value specs?

    // MARK: - Working bees

    enum Header: String {
        case pEpKeyImport = "pEp-key-import"
    }

    private func isKeyImportMessage(message: Message) -> Bool {
        return message.optionalFields[Header.pEpKeyImport.rawValue] != nil
    }

    private func isPrivateKeyMessage(message: Message, flags: PEP_decrypt_flags) -> Bool {
        let hasOwnPrivateKey = flags.rawValue & PEP_decrypt_flag_own_private_key.rawValue == 1
        let isGreen = message.pEpColor() == PEP_color_green
        return isGreen && hasOwnPrivateKey
    }

    private func timedOut(keyImportMessage message: Message) -> Bool {
        guard let age = message.received?.timeIntervalSinceNow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No received date.")
            return true
        }
        return age < -KeyImportService.ttlKeyImportMessages
    }

    private func informDelegateNewKeyImportMessageArrived(message: Message) {
        if !timedOut(keyImportMessage: message) {
            // Don't bother the delegate with invalid messages.
            delegate?.newKeyImportMessageArrived(message: message)
        }
    }

    private func informDelegateReceivedPrivateKey(message: Message) {
        delegate?.receivedPrivateKey(forAccount: message.parent.account) //IOS-1028: needs timeout too?
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
        var hasBeenHandled = false
        if isKeyImportMessage(message: msg) {
            hasBeenHandled = true
            msg.imapMarkDeleted()
            informDelegateNewKeyImportMessageArrived(message: msg)
        } else if isPrivateKeyMessage(message: msg, flags: flags) {
            hasBeenHandled = true
            msg.imapMarkDeleted()
            informDelegateReceivedPrivateKey(message: msg)
        }
        return hasBeenHandled
    }
}
