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

    /// Specifies the time to live for key import messages
    let timeoutInterval: TimeInterval = 5 * 60 //IOS-1028: timeout value specs?

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
            msg.imapMarkDeleted()
            hasBeenHandled = true
            if !timedOut(keyImportMessage: msg) {
                delegate?.newKeyImportMessageArrived(message: msg)
            }
        } else if isPrivateKeyMessage(message: msg, flags: flags) {
            msg.imapMarkDeleted()
            hasBeenHandled = true
            delegate?.receivedPrivateKey(forAccount: msg.parent.account) //IOS-1028: needs timeout too?
        }
        return hasBeenHandled
    }

    private func timedOut(keyImportMessage message: Message) -> Bool {
        guard let age = message.received?.timeIntervalSinceNow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No received date.")
            return true
        }
        return age < -timeoutInterval
    }
}
