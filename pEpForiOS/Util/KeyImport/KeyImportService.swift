//
//  KeyImportService.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Only for tests.
protocol UnitTestDelegateKeyImportService: class {
    func KeyImportService(keyImportService: KeyImportService,
                          didSendKeyimportMessage message: Message)
}

public enum KeyImportServiceError: Error {
    case smtpError
    case engineError
}

public class KeyImportService {
    enum Header: String {
        case pEpKeyImport = "pEp-key-import"
    }

    public weak var delegate: KeyImportServiceDelegate?
    weak var unitTestDelegate: UnitTestDelegateKeyImportService?

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

    /// Sends a message. In case fpr != nil, the message is encrypted using this key before sending.
    ///
    /// - Parameters:
    ///   - msg: message to send
    ///   - account: account to send from
    ///   - fpr: fpr of key to decrypt message with.
    private func sendMessage(msg: Message,
                             fromAccount account: Account,
                             encryptFor fpr: String? = nil) {
        // Login OP
        guard let sendData = smtpSendData(for: account) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No send data") //IOS-1028: test, extract send, test. Think: Error delegate.
            return
        }
        let errorContainer = ErrorContainer() //IOS-1028: make property
        let loginOp = LoginSmtpOperation(smtpSendData: sendData, errorContainer: errorContainer)

        // Send OP
        guard let sendOp = buildSendOP(toSend: msg,
                                 fromAccount: account,
                                 smtpSendData: sendData,
                                 errorContainer: errorContainer)
            else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "No OP")
                return
        }

        sendOp.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            if errorContainer.hasErrors() {
                me.delegate?.errorOccurred(error: KeyImportServiceError.smtpError)
            }
            // Only for Unit Test
            me.unitTestDelegate?.KeyImportService(keyImportService: me,
                                                  didSendKeyimportMessage: msg)
        }
        sendOp.addDependency(loginOp)

        // Go!
        queue.addOperations([loginOp, sendOp], waitUntilFinished: false)
    }

    /// Send op to send the given message.
    /// In case fpr != nil, the message is encrypted using this key before sending.
    private func buildSendOP(toSend msg: Message,
                             fromAccount account: Account,
                             encryptFor fpr: String? = nil,
                             smtpSendData: SmtpSendData,
                             errorContainer: ErrorContainer) -> SMTPSendOperation? {
        // send OP
        var pepDict = msg.pEpMessageDict(outgoing: true)
        if let fpr = fpr {
            let extraKeys =  [fpr]
            do {
                let encryptedMessage = try PEPSession().encryptMessageDict(pepDict,
                                                                           extraKeys: extraKeys,
                                                                           encFormat: PEP_enc_PEP,
                                                                           status: nil)
                    as PEPMessageDict
                pepDict = encryptedMessage
            } catch {
                delegate?.errorOccurred(error: KeyImportServiceError.engineError)
                return nil
            }
        }
        return SMTPSendOperation(errorContainer: errorContainer,
                                       messageDict: pepDict,
                                       smtpSendData: smtpSendData)
    }

    private func createKeyImportMessage(for account: Account, setPEpKeyImportHeader: Bool) -> Message? {
        guard let dummyFolder = account.folder(ofType: .sent) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder")
            return nil
        }
        let msg = Message(uuid: MessageID.generateUUID(), parentFolder: dummyFolder)
        let mySelf = account.user
        msg.from = mySelf
        msg.to = [mySelf]
        if setPEpKeyImportHeader {
            guard let myFpr = fingerprint(forAccount: account) else {
                Log.shared.errorAndCrash(component: #function, errorString: "No FPR")
                return nil
            }
            msg.optionalFields[Header.pEpKeyImport.rawValue] = myFpr
        }
        return msg
    }
}

// MARK: - KeyImportServiceProtocol

extension KeyImportService: KeyImportServiceProtocol {

    /// Call to inform the other device that we would love to start a Key Import session.
    /// Sends an unencrypted message with header: "pEp-key-import: myPubKey_fpr" to myself (without
    /// appending the message to "Sent" folder)
    public func sendInitKeyImportMessage(forAccount account: Account) {
        guard let msg = createKeyImportMessage(for: account, setPEpKeyImportHeader: true) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No message")
            return
        }
        sendMessage(msg: msg, fromAccount: account)
    }

    /// Call after a newKeyImportMessage arrived to let the other device know
    /// we are ready for handshake.
    public func sendHandshakeRequest(forAccount account: Account, fpr: String) {
        guard let msg = createKeyImportMessage(for: account, setPEpKeyImportHeader: true) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No message")
            return
        }

        sendMessage(msg: msg, fromAccount: account, encryptFor: fpr)
    }

    public func sendOwnPrivateKey(forAccount acccount: Account, fpr: String) {
        /// TODO: Send the private key without appending to "Sent" folder.

        fatalError("Unimplemented stub")
    }

    public func setNewDefaultKey(for identity: Identity, fpr: String) {
        do {
            try PEPSession().setOwnKey(identity.pEpIdentity(), fingerprint: fpr)
        } catch {
            delegate?.errorOccurred(error: KeyImportServiceError.engineError)
        }
    }
}

// MARK: - KeyImportListenerProtocol

extension KeyImportService: KeyImportListenerProtocol {
    public func handleKeyImport(forMessage msg: Message, flags: PEP_decrypt_flags) -> Bool {
        var hasBeenHandled = false
        if timedOut(keyImportMessage: msg) {
            return hasBeenHandled
        }
        if isKeyNewInitKeyImportMessage(message: msg){
            hasBeenHandled = true
            msg.imapMarkDeleted()
            delegate?.newInitKeyImportRequestMessageArrived(message: msg)
        }else if isNewHandshakeRequestMessage(message: msg){
            hasBeenHandled = true
            msg.imapMarkDeleted()
            delegate?.newHandshakeRequestMessageArrived(message: msg)
        } else if isPrivateKeyMessage(message: msg, flags: flags) {
            hasBeenHandled = true
            msg.imapMarkDeleted()
            delegate?.receivedPrivateKey(forAccount: msg.parent.account)
        }
        return hasBeenHandled
    }
}
