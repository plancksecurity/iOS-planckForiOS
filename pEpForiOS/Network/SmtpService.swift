//
//  SmtpSend.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol SmtpSendDelegate: class {
    func messageSent(_ smtp: SmtpSend, theNotification: Notification?)
    func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionLost(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?)
    func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?)
    func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?)
    func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?)
}

open class SmtpSendDefaultDelegate: SmtpSendDelegate {
    open func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}

    public init() {}
}

struct SmtpStatus {
    var haveStartedTLS = false
}

open class SmtpSend: Service {
    open override var comp: String { get { return "SmtpSend" } }

    fileprivate var smtpStatus: SmtpStatus = SmtpStatus.init()
    weak open var delegate: SmtpSendDelegate?

    var smtp: CWSMTP {
        get {
            return service as! CWSMTP
        }
    }

    open override func createService() -> CWService {
        return CWSMTP.init(name: connectInfo.networkAddress,
                           port: UInt32(connectInfo.networkPort),
                           transport: connectInfo.connectionTransport!)
    }

    fileprivate func createMessage() -> CWMessage {
        let msg = CWMessage.init()
        msg.setSubject("Subject Message")
        msg.setFrom(CWInternetAddress.init(personal: "Unit 004",
            address: "unittest.ios.4@peptest.ch"))

        let to = CWInternetAddress.init(personal: "Unit 001", address: "unittest.ios.1@peptest.ch")
        to?.setType(.toRecipient)
        msg.addRecipient(to!)

        msg.setContentType(Constants.contentTypeText)
        msg.setContentTransferEncoding(PantomimeEncodingNone)
        msg.setCharset("utf-8")
        msg.setContent("This was sent by pantomime".data(using: String.Encoding.utf8) as NSObject?)
        return msg
    }

    fileprivate func sendMessage() {
        smtp.setRecipients(nil)
        smtp.setMessageData(nil)
        smtp.setMessage(createMessage())
        smtp.sendMessage()
    }

    /**
     Resets the connection. Do this for each mail.
     */
    open func reset() {
        smtp.reset()
    }
}

extension SmtpSend: TransportClient {

    @objc public func messageSent(_ theNotification: Notification?) {
        dumpMethodName("messageSent", notification: theNotification)
        delegate?.messageSent(self, theNotification: theNotification)
    }

    @objc public func messageNotSent(_ theNotification: Notification?) {
        dumpMethodName("messageNotSent", notification: theNotification)
        delegate?.messageNotSent(self, theNotification: theNotification)
    }
}

extension SmtpSend: SMTPClient {
    @objc public func transactionInitiationCompleted(_ theNotification: Notification?) {
        dumpMethodName("transactionInitiationCompleted", notification: theNotification)
        delegate?.transactionInitiationCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionInitiationFailed(_ theNotification: Notification?) {
        dumpMethodName("transactionInitiationFailed", notification: theNotification)
        delegate?.transactionInitiationFailed(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationCompleted(_ theNotification: Notification?) {
        dumpMethodName("recipientIdentificationCompleted", notification: theNotification)
        delegate?.recipientIdentificationCompleted(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationFailed(_ theNotification: Notification?) {
        dumpMethodName("recipientIdentificationFailed", notification: theNotification)
        delegate?.recipientIdentificationFailed(self, theNotification: theNotification)
    }

    @objc public func transactionResetCompleted(_ theNotification: Notification?) {
        dumpMethodName("transactionResetCompleted", notification: theNotification)
        delegate?.transactionResetCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionResetFailed(_ theNotification: Notification?) {
        dumpMethodName("transactionResetFailed", notification: theNotification)
        delegate?.transactionResetFailed(self, theNotification: theNotification)
    }
}

extension SmtpSend: CWServiceClient {
    @objc public func authenticationCompleted(_ theNotification: Notification?) {
        dumpMethodName("authenticationCompleted", notification: theNotification)
        delegate?.authenticationCompleted(self, theNotification: theNotification)
    }

    @objc public func authenticationFailed(_ theNotification: Notification?) {
        dumpMethodName("authenticationFailed", notification: theNotification)
        delegate?.authenticationFailed(self, theNotification: theNotification)
    }

    @objc public func connectionEstablished(_ theNotification: Notification?) {
        dumpMethodName("connectionEstablished", notification: theNotification)
        delegate?.connectionEstablished(self, theNotification: theNotification)
    }

    @objc public func connectionLost(_ theNotification: Notification?) {
        dumpMethodName("connectionLost", notification: theNotification)
        delegate?.connectionLost(self, theNotification: theNotification)
    }

    @objc public func connectionTerminated(_ theNotification: Notification?) {
        dumpMethodName("connectionTerminated", notification: theNotification)
        delegate?.connectionTerminated(self, theNotification: theNotification)
    }

    @objc public func connectionTimedOut(_ theNotification: Notification?) {
        dumpMethodName("connectionTimedOut", notification: theNotification)
        delegate?.connectionTimedOut(self, theNotification: theNotification)
    }

    @objc public func requestCancelled(_ theNotification: Notification?) {
        dumpMethodName("requestCancelled", notification: theNotification)
        delegate?.requestCancelled(self, theNotification: theNotification)
    }

    @objc public func serviceInitialized(_ theNotification: Notification?) {
        dumpMethodName("serviceInitialized", notification: theNotification)
        delegate?.serviceInitialized(self, theNotification: theNotification)
        if self.connectInfo.connectionTransport == ConnectionTransport.startTLS &&
            !self.smtpStatus.haveStartedTLS {
            self.smtpStatus.haveStartedTLS = true
            self.smtp.startTLS()
        } else {
            var password: String!
            if let pass = self.connectInfo.userPassword {
                password = pass
            } else {
                password = KeyChain.getPassword(self.connectInfo.userId,
                                                serverType: connectInfo.networkAddress)
            }
            self.smtp.authenticate(self.connectInfo.userId,
                                   password: password,
                                   mechanism: self.bestAuthMethod().rawValue)
        }
    }

    @objc public func serviceReconnected(_ theNotification: Notification?) {
        dumpMethodName("serviceReconnected", notification: theNotification)
        delegate?.serviceReconnected(self, theNotification: theNotification)
   }
}
