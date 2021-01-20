//
//  SmtpConnection.swift
//  pEp-share
//
//  Created by Adam Kowalski on 18/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework
import PEPObjCAdapterFramework
import pEpIOSToolbox

protocol SmtpConnectionDelegate: class {
    func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?)
}

extension SmtpConnectAndSendMessage {
    private struct Status {
        var haveStartedTLS = false
    }
}

final class SmtpConnectAndSendMessage: SmtpConnectionProtocol {

    let accountAddress: String
    let isClientCertificateSet: Bool = false
    private let connectionTransport: ConnectionTransport
    private let networkAddress: String
    private let networkPort: UInt32
    private let loginName: String
    private let loginPassword: String

    private var smtp: CWSMTP

    private var smtpStatus: Status = Status()
    weak var delegate: SmtpConnectionDelegate?

    init(accountAddress: String,
         connectionTransport: ConnectionTransport,
         serverAddress: String,
         serverPort: UInt32,
         loginName: String,
         loginPassword: String) {

        self.accountAddress = accountAddress
        self.connectionTransport = connectionTransport
        self.networkAddress = serverAddress
        self.networkPort = serverPort
        self.loginName = loginName
        self.loginPassword = loginPassword

        smtp = CWSMTP(name: networkAddress,
                      port: networkPort,
                      transport: ConnectionTransport.startTLS,
                      clientCertificate: nil)

        smtp.setDelegate(self)

        print("DEV: init -> SmtpConnection")
    }

    deinit {
        print("DEV: deinit -> SmtpConnection")
    }

    func start() {
        smtp.connectInBackgroundAndNotify()
    }
}

// MARK: - Wrap CWSMTP methods

extension SmtpConnectAndSendMessage {
    func setRecipients(_ recipients: [Any]?) {
        smtp.setRecipients(recipients)
    }

    func setMessageData(_ data: Data?) {
        smtp.setMessageData(data)
    }

    func setMessage(_ message: CWMessage) {
        smtp.setMessage(message)
    }

    func sendMessage() {
        smtp.sendMessage()
    }
}

extension SmtpConnectAndSendMessage: CWConnectionDelegate {
    func connectionEstablished() {
        print("DEV: connectionEstablished :-)")
    }

    func receivedEvent(_ theData: UnsafeMutableRawPointer?, type theType: RunLoopEventType, extra theExtra: UnsafeMutableRawPointer?, forMode theMode: String?) {
        print("DEV: receivedEvent :-)")
    }
}

// MARK: - TransportClient

extension SmtpConnectAndSendMessage: TransportClient {
    @objc public func messageSent(_ theNotification: Notification?) {
        delegate?.messageSent(self, theNotification: theNotification)
        print("DEV: messageSent")
        // close connection
        smtp.close()
    }

    @objc public func messageNotSent(_ theNotification: Notification?) {
        delegate?.messageNotSent(self, theNotification: theNotification)
        print("DEV: messageNotSent!")
    }
}

// MARK: - SMTPClient

extension SmtpConnectAndSendMessage: SMTPClient {
    @objc public func transactionInitiationCompleted(_ theNotification: Notification?) {
        delegate?.transactionInitiationCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionInitiationFailed(_ theNotification: Notification?) {
        delegate?.transactionInitiationFailed(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationCompleted(_ theNotification: Notification?) {
        delegate?.recipientIdentificationCompleted(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationFailed(_ theNotification: Notification?) {
        delegate?.recipientIdentificationFailed(self, theNotification: theNotification)
    }

    @objc public func transactionResetCompleted(_ theNotification: Notification?) {
        delegate?.transactionResetCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionResetFailed(_ theNotification: Notification?) {
        delegate?.transactionResetFailed(self, theNotification: theNotification)
    }
}

// MARK: - CWServiceClient

extension SmtpConnectAndSendMessage: CWServiceClient {
    @objc public func badResponse(_ theNotification: Notification?) {
        delegate?.badResponse(self, response: "error!")
    }

    @objc public func authenticationCompleted(_ theNotification: Notification?) {
            delegate?.authenticationCompleted(self, theNotification: theNotification)

        // !!! WIP: - Only temporary
        sendMessage()
    }

    @objc public func authenticationFailed(_ theNotification: Notification?) {
        delegate?.authenticationFailed(self, theNotification: theNotification)
    }

    @objc public func connectionEstablished(_ theNotification: Notification?) {
        delegate?.connectionEstablished(self, theNotification: theNotification)
    }

    @objc public func connectionLost(_ theNotification: Notification?) {
        delegate?.connectionLost(self, theNotification: theNotification)
    }

    @objc public func connectionTerminated(_ theNotification: Notification?) {
        delegate?.connectionTerminated(self, theNotification: theNotification)
    }

    @objc public func connectionTimedOut(_ theNotification: Notification?) {
        delegate?.connectionTimedOut(self, theNotification: theNotification)
    }

    @objc public func requestCancelled(_ theNotification: Notification?) {
        delegate?.requestCancelled(self, theNotification: theNotification)
    }

    @objc public func serviceInitialized(_ theNotification: Notification?) {
        delegate?.serviceInitialized(self, theNotification: theNotification)
        if connectionTransport == ConnectionTransport.startTLS &&
            !smtpStatus.haveStartedTLS {
            smtpStatus.haveStartedTLS = true
            smtp.startTLS()
        } else {
             let password = loginPassword
             let theLoginName = loginName
                smtp.authenticate(theLoginName,
                                  password: password,
                                  mechanism: "plain")

        }
    }

    @objc public func serviceReconnected(_ theNotification: Notification?) {
        delegate?.serviceReconnected(self, theNotification: theNotification)
   }
}
