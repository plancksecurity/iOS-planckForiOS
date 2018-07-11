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
        if message.parent.folderType != .inbox {
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

    /// Sends a message.
    /// In case fpr != nil, the message is encrypted using this key before sending.
    /// In case fpr != nil && attachPrivateKey == true, the private key is attached before
    /// encrypting and sending the message.
    ///
    /// - Parameters:
    ///   - msg: message to send
    ///   - account: account to send from
    ///   - fpr: fpr of key to decrypt message with.
    ///   - attachPrivateKey: whether or not to attach our private key
    private func sendMessage(msg: Message,
                             fromAccount account: Account,
                             encryptFor fpr: String? = nil,
                             attachPrivateKey: Bool = false) {
        // Build Login OP
        guard let sendData = smtpSendData(for: account) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No send data")
            return
        }
        let errorContainer = ErrorContainer()
        let loginOp = LoginSmtpOperation(smtpSendData: sendData, errorContainer: errorContainer)

        // Build Send OP
        let sendOp = encryptAndSendOperation(toSend: msg,
                                 fromAccount: account,
                                 encryptFor: fpr,
                                 attachPrivateKey: attachPrivateKey,
                                 smtpSendData: sendData,
                                 errorContainer: errorContainer)
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
    private func encryptAndSendOperation(toSend msg: Message,
                                         fromAccount account: Account,
                                         encryptFor fpr: String? = nil,
                                         attachPrivateKey: Bool = false,
                                         smtpSendData: SmtpSendData,
                                         errorContainer: ErrorContainer) -> Operation {
        return BlockOperation() {[weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            let queue = OperationQueue()
            var pepDict = msg.pEpMessageDict(outgoing: true)
            if let fpr = fpr {
                guard let encrypted = me.encrypt(message: msg,
                                                 for: fpr,
                                                 attachPrivateKey: attachPrivateKey)
                    else {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString: "Error encrypting")
                        me.delegate?.errorOccurred(error: KeyImportServiceError.engineError)
                        return
                }
                pepDict = encrypted
            }
            let sendOP = SMTPSendOperation(errorContainer: errorContainer,
                                           messageDict: pepDict,
                                           smtpSendData: smtpSendData)
            sendOP.completionBlock = {
                if errorContainer.hasErrors() {
                    me.delegate?.errorOccurred(error: KeyImportServiceError.smtpError)
                }
            }
            queue.addOperations([sendOP], waitUntilFinished: true)
        }
    }

    private func encrypt(message: Message,
                         for fpr: String,
                         attachPrivateKey: Bool = false) -> PEPMessageDict? {
        let pepDict = message.pEpMessageDict(outgoing: true)
        let extraKeys =  [fpr]
        var result: PEPMessageDict? = nil
        do {
            if attachPrivateKey {
                let flags = PEP_decrypt_flag_none
                result = try PEPSession().encryptMessageDict(pepDict,
                                                    toFpr: fpr,
                                                    encFormat: PEP_enc_PEP,
                                                    flags: flags,
                                                    status: nil)
                    as PEPMessageDict
            } else {
                result = try PEPSession().encryptMessageDict(pepDict,
                                                           extraKeys: extraKeys,
                                                           encFormat: PEP_enc_PEP,
                                                           status: nil)
                    as PEPMessageDict
            }
        } catch {
            Log.shared.errorAndCrash(component: #function, errorString: "Error encrypting")
            delegate?.errorOccurred(error: KeyImportServiceError.engineError)
            return result
        }

        return result
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

    public func sendOwnPrivateKey(forAccount account: Account, fpr: String) {
        guard let msg = createKeyImportMessage(for: account, setPEpKeyImportHeader: true) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No message")
            return
        }
        sendMessage(msg: msg, fromAccount: account, encryptFor: fpr, attachPrivateKey: true)
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
            return hasBeenHandled //IOS-1028: delete timeedout message?
        }

        if isKeyNewInitKeyImportMessage(message: msg){
            hasBeenHandled = true
            msg.imapMarkDeleted()
            guard let fpr = msg.optionalFields[Header.pEpKeyImport.rawValue] else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "No fpr header. Impossible in this state.")
                return false
            }
            delegate?.newInitKeyImportRequestMessageArrived(forAccount: msg.parent.account,
                                                            fpr: fpr)
        } else if isNewHandshakeRequestMessage(message: msg){
            hasBeenHandled = true
            msg.imapMarkDeleted()
            guard let fpr = msg.optionalFields[Header.pEpKeyImport.rawValue] else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "No fpr header. Impossible in this state.")
                return false
            }
            delegate?.newHandshakeRequestMessageArrived(forAccount: msg.parent.account,
                                                        fpr: fpr)
        } else if isPrivateKeyMessage(message: msg, flags: flags) {
            hasBeenHandled = true
            msg.imapMarkDeleted()
            delegate?.receivedPrivateKey(forAccount: msg.parent.account)
        }
        return hasBeenHandled
    }
}
