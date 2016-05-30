//
//  SmtpSend.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol SmtpSendDelegate: class {
    func messageSent(smtp: SmtpSend, theNotification: NSNotification?)
    func messageNotSent(smtp: SmtpSend, theNotification: NSNotification?)
    func transactionInitiationCompleted(smtp: SmtpSend, theNotification: NSNotification?)
    func transactionInitiationFailed(smtp: SmtpSend, theNotification: NSNotification?)
    func recipientIdentificationCompleted(smtp: SmtpSend, theNotification: NSNotification?)
    func recipientIdentificationFailed(smtp: SmtpSend, theNotification: NSNotification?)
    func transactionResetCompleted(smtp: SmtpSend, theNotification: NSNotification?)
    func transactionResetFailed(smtp: SmtpSend, theNotification: NSNotification?)
    func authenticationCompleted(smtp: SmtpSend, theNotification: NSNotification?)
    func authenticationFailed(smtp: SmtpSend, theNotification: NSNotification?)
    func connectionEstablished(smtp: SmtpSend, theNotification: NSNotification?)
    func connectionLost(smtp: SmtpSend, theNotification: NSNotification?)
    func connectionTerminated(smtp: SmtpSend, theNotification: NSNotification?)
    func connectionTimedOut(smtp: SmtpSend, theNotification: NSNotification?)
    func requestCancelled(smtp: SmtpSend, theNotification: NSNotification?)
    func serviceInitialized(smtp: SmtpSend, theNotification: NSNotification?)
    func serviceReconnected(smtp: SmtpSend, theNotification: NSNotification?)
}

public class SmtpSendDefaultDelegate: SmtpSendDelegate {
    public func messageSent(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func messageNotSent(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func transactionInitiationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func transactionInitiationFailed(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func recipientIdentificationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func recipientIdentificationFailed(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func transactionResetCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func transactionResetFailed(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func authenticationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func authenticationFailed(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func connectionEstablished(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func connectionLost(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func connectionTerminated(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func connectionTimedOut(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func requestCancelled(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func serviceInitialized(smtp: SmtpSend, theNotification: NSNotification?) {}
    public func serviceReconnected(smtp: SmtpSend, theNotification: NSNotification?) {}

    public init() {}
}

struct SmtpStatus {
    var haveStartedTLS = false
}

public class SmtpSend: Service {
    public override var comp: String { get { return "SmtpSend" } }

    private var smtpStatus: SmtpStatus = SmtpStatus.init()
    weak public var delegate: SmtpSendDelegate?

    var smtp: CWSMTP {
        get {
            return service as! CWSMTP
        }
    }

    public override func createService() -> CWService {
        return CWSMTP.init(name: connectInfo.smtpServerName,
                           port: UInt32(connectInfo.smtpServerPort),
                           transport: connectInfo.smtpTransport)
    }

    private func createMessage() -> CWMessage {
        let msg = CWMessage.init()
        msg.setSubject("Subject Message")
        msg.setFrom(CWInternetAddress.init(personal: "Test 001", address: "test001@peptest.ch"))

        let to = CWInternetAddress.init(personal: "Test 002", address: "test002@peptest.ch")
        to.setType(PantomimeToRecipient)
        msg.addRecipient(to)

        msg.setContentType(Constants.contentTypeText)
        msg.setContentTransferEncoding(PantomimeEncodingNone)
        msg.setCharset("utf-8")
        msg.setContent("This was sent by pantomime".dataUsingEncoding(NSUTF8StringEncoding))
        return msg
    }

    private func sendMessage() {
        smtp.setRecipients(nil)
        smtp.setMessageData(nil)
        smtp.setMessage(createMessage())
        smtp.sendMessage()
    }
}

extension SmtpSend: TransportClient {

    @objc public func messageSent(theNotification: NSNotification?) {
        dumpMethodName("messageSent", notification: theNotification)
        delegate?.messageSent(self, theNotification: theNotification)
    }

    @objc public func messageNotSent(theNotification: NSNotification?) {
        dumpMethodName("messageNotSent", notification: theNotification)
        delegate?.messageNotSent(self, theNotification: theNotification)
    }
}

extension SmtpSend: SMTPClient {
    @objc public func transactionInitiationCompleted(theNotification: NSNotification?) {
        dumpMethodName("transactionInitiationCompleted", notification: theNotification)
        delegate?.transactionInitiationCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionInitiationFailed(theNotification: NSNotification?) {
        dumpMethodName("transactionInitiationFailed", notification: theNotification)
        delegate?.transactionInitiationFailed(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationCompleted(theNotification: NSNotification?) {
        dumpMethodName("recipientIdentificationCompleted", notification: theNotification)
        delegate?.recipientIdentificationCompleted(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationFailed(theNotification: NSNotification?) {
        dumpMethodName("recipientIdentificationFailed", notification: theNotification)
        delegate?.recipientIdentificationFailed(self, theNotification: theNotification)
    }

    @objc public func transactionResetCompleted(theNotification: NSNotification?) {
        dumpMethodName("transactionResetCompleted", notification: theNotification)
        delegate?.transactionResetCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionResetFailed(theNotification: NSNotification?) {
        dumpMethodName("transactionResetFailed", notification: theNotification)
        delegate?.transactionResetFailed(self, theNotification: theNotification)
    }
}

extension SmtpSend: CWServiceClient {
    @objc public func authenticationCompleted(theNotification: NSNotification?) {
        dumpMethodName("authenticationCompleted", notification: theNotification)
        delegate?.authenticationCompleted(self, theNotification: theNotification)
    }

    @objc public func authenticationFailed(theNotification: NSNotification?) {
        dumpMethodName("authenticationFailed", notification: theNotification)
        delegate?.authenticationFailed(self, theNotification: theNotification)
    }

    @objc public func connectionEstablished(theNotification: NSNotification?) {
        dumpMethodName("connectionEstablished", notification: theNotification)
        delegate?.connectionEstablished(self, theNotification: theNotification)
    }

    @objc public func connectionLost(theNotification: NSNotification?) {
        dumpMethodName("connectionLost", notification: theNotification)
        delegate?.connectionLost(self, theNotification: theNotification)
    }

    @objc public func connectionTerminated(theNotification: NSNotification?) {
        dumpMethodName("connectionTerminated", notification: theNotification)
        delegate?.connectionTerminated(self, theNotification: theNotification)
    }

    @objc public func connectionTimedOut(theNotification: NSNotification?) {
        dumpMethodName("connectionTimedOut", notification: theNotification)
        delegate?.connectionTimedOut(self, theNotification: theNotification)
    }

    @objc public func requestCancelled(theNotification: NSNotification?) {
        dumpMethodName("requestCancelled", notification: theNotification)
        delegate?.requestCancelled(self, theNotification: theNotification)
    }

    @objc public func serviceInitialized(theNotification: NSNotification?) {
        dumpMethodName("serviceInitialized", notification: theNotification)
        delegate?.serviceInitialized(self, theNotification: theNotification)
        if self.connectInfo.smtpTransport == ConnectionTransport.StartTLS &&
            !self.smtpStatus.haveStartedTLS {
            self.smtpStatus.haveStartedTLS = true
            self.smtp.startTLS()
        } else {
            var password: String!
            if let pass = self.connectInfo.smtpPassword {
                password = pass
            } else {
                password = KeyChain.getPassword(self.connectInfo.email,
                                                serverType: Account.AccountType.SMTP.asString())
            }
            self.smtp.authenticate(self.connectInfo.getSmtpUsername(),
                                   password: password,
                                   mechanism: self.bestAuthMethod().rawValue)
        }
    }

    @objc public func serviceReconnected(theNotification: NSNotification?) {
        dumpMethodName("serviceReconnected", notification: theNotification)
        delegate?.serviceReconnected(self, theNotification: theNotification)
   }
}