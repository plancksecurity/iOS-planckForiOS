//
//  KeyImportService.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

public enum KeyImportServiceError: Error {
    case smtpError
    case engineError
}

public class KeyImportService {
    public weak var delegate: KeyImportServiceDelegate?
    /// Specifies how long a key import message is valid
    static let ttlKeyImportMessages: TimeInterval = 4 * 60 * 60
    /// Work queue
    let queue: OperationQueue

    // MARK: - Life Cycle
    init() {
        queue = OperationQueue()
        queue.name = "pep.security.KeyImportService"
    }

    // MARK: - Working bees

    enum Header: String {
        case pEpKeyImport = "pEp-key-import"
    }

    private func isKeyNewInitKeyImportMessage(message: Message) -> Bool {
        return isKeyImportMessage(message: message, pepColorIs: PEP_color_no_color)
    }

    private func isNewHandshakeRequestMessage(message: Message) -> Bool {
        return isKeyImportMessage(message: message, pepColorIs: PEP_color_yellow)
    }

    private func isKeyImportMessage(message: Message, pepColorIs requiredColor: PEP_color) -> Bool {
        guard let myFpr = fingerprint(forAccount: message.parent.account) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No own key")
            return false
        }
        let requestFpr = message.optionalFields[Header.pEpKeyImport.rawValue]
        let messageColor = message.pEpColor()
        return requestFpr != nil && requestFpr != myFpr && messageColor == requiredColor
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

    private func informDelegateNewInitKeyImportRequestMessageArrived(message: Message) {
        if !timedOut(keyImportMessage: message) {
            // Don't bother the delegate with invalid messages.
            delegate?.newInitKeyImportRequestMessageArrived(message: message)
        }
    }

    private func informDelegateNewHandshakeRequestMessageArrived(message: Message) {
        if !timedOut(keyImportMessage: message) {
            // Don't bother the delegate with invalid messages.
            delegate?.newHandshakeRequestMessageArrived(message: message)
        }
    }

    private func informDelegateReceivedPrivateKey(message: Message) {
        if !timedOut(keyImportMessage: message) {
            // Don't bother the delegate with invalid messages.
            delegate?.receivedPrivateKey(forAccount: message.parent.account)
        }
    }

    private func fingerprint(forAccount acc: Account) -> String? {
        let pEpMe = acc.user.pEpIdentity()
        do {
            try PEPSession().mySelf(pEpMe)
            return pEpMe.fingerPrint
        } catch {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "myself error: \(error.localizedDescription)")
            return nil
        }
    }

    private func smtpSendData(for account: Account) -> SmtpSendData? {
        guard let smtpCI = account.smtpConnectInfo else {
            Log.shared.errorAndCrash(component: #function, errorString: "No connect info")
            return nil
        }
        return  SmtpSendData(connectInfo: smtpCI)
    }
}

// MARK: - KeyImportServiceProtocol

extension KeyImportService: KeyImportServiceProtocol {
    /// Call after successfull handshake.
    public func sendOwnPrivateKey(inAnswerToRequestMessage msg: Message) {
        /// TODO: Send the private key without appending to "Sent" folder.
        fatalError("Unimplemented stub")
    }

    /// Call to inform the other device that we would love to start a Key Import session.
    /// Sends an unencrypted message with header: "pEp-key-import: myPubKey_fpr" to myself (without
    /// appending the message to "Sent" folder)
    public func sendInitKeyImportMessage(forAccount account: Account) {

        guard let dummyFolder = account.folder(ofType: .sent) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder")
            return
        }

        guard let myFpr = fingerprint(forAccount: account) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No FPR")
            return
        }

        let msg = Message(uuid: MessageID.generateUUID(), parentFolder: dummyFolder)
        let mySelf = account.user
        msg.from = mySelf
        msg.to = [mySelf]
        msg.optionalFields[Header.pEpKeyImport.rawValue] = myFpr

        // Login OP
        guard let sendData = smtpSendData(for: account) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No send data") //IOS-1028: test, extract send, test. Think: Error delegate.
            return
        }
        let errorContainer = ErrorContainer() //IOS-1028: make property
        let loginOp = LoginSmtpOperation(smtpSendData: sendData, errorContainer: errorContainer)
        // send OP
        let sendOp = SMTPSendOperation(errorContainer: errorContainer,
                                       messageToSend: msg,
                                       smtpSendData: sendData)
        //IOS-1028: handle errors, add test-success-delegate or such
        // Go!
        queue.addOperations([loginOp, sendOp], waitUntilFinished: false)
    }

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    public func sendHandshakeRequest(forAccount account: Account) {
        //TODO: send encrypted message to myself with header: "pEp-key-import: myPubKey_fpr" (assume: without appending to sent folder)
        fatalError("Unimplemented stub")
    }

    public func setNewDefaultKey(for identity: Identity, fpr: String) {
        do {
            try PEPSession().setOwnKey(identity.pEpIdentity(), fingerprint: fpr)
        } catch {
            //TODO: handle error
        }
    }
}

// MARK: - KeyImportListenerProtocol

extension KeyImportService: KeyImportListenerProtocol {
    public func handleKeyImport(forMessage msg: Message, flags: PEP_decrypt_flags) -> Bool {
        var hasBeenHandled = false
        if isKeyNewInitKeyImportMessage(message: msg){
            hasBeenHandled = true
            msg.imapMarkDeleted()
            informDelegateNewInitKeyImportRequestMessageArrived(message: msg)
        }else if isNewHandshakeRequestMessage(message: msg){
            hasBeenHandled = true
            msg.imapMarkDeleted()
            informDelegateNewHandshakeRequestMessageArrived(message: msg)
        } else if isPrivateKeyMessage(message: msg, flags: flags) {
            hasBeenHandled = true
            msg.imapMarkDeleted()
            informDelegateReceivedPrivateKey(message: msg)
        }
        return hasBeenHandled
    }
}
