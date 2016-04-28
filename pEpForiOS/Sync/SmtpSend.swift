//
//  SmtpSend.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

struct SmtpStatus {
    var haveStartedTLS = false
}

public class SmtpSend: Service {
    private let comp = "SmtpSend"

    private var smtpStatus: SmtpStatus = SmtpStatus.init()
    private var messagesSent = 0
    private var maxMessageToSend = 3

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

    private func dumpMethodName(methodName: String, notification: NSNotification) {
        Log.info(comp, "\(methodName): \(notification)")
    }

    private func createMessage() -> CWMessage {
        let msg = CWMessage.init()
        msg.setSubject("Subject Message \(messagesSent + 1)")
        msg.setFrom(CWInternetAddress.init(personal: "Test 001", address: "test001@peptest.ch"))

        let to = CWInternetAddress.init(personal: "Test 002", address: "test002@peptest.ch")
        to.setType(PantomimeToRecipient)
        msg.addRecipient(to)

        msg.setContentType("text/plain")
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

    @objc public func messageSent(theNotification: NSNotification!) {
        dumpMethodName("messageSent", notification: theNotification)
        messagesSent += 1
        if messagesSent < maxMessageToSend {
            smtp.reset()
        } else {
            smtp.close()
        }
    }

    @objc public func messageNotSent(theNotification: NSNotification!) {
        dumpMethodName("messageNotSent", notification: theNotification)
    }
}

extension SmtpSend: SMTPClient {
    @objc public func transactionInitiationCompleted(theNotification: NSNotification!) {
        dumpMethodName("transactionInitiationCompleted", notification: theNotification)
    }

    @objc public func transactionInitiationFailed(theNotification: NSNotification!) {
        dumpMethodName("transactionInitiationFailed", notification: theNotification)
    }

    @objc public func recipientIdentificationCompleted(theNotification: NSNotification!) {
        dumpMethodName("recipientIdentificationCompleted", notification: theNotification)
    }

    @objc public func recipientIdentificationFailed(theNotification: NSNotification!) {
        dumpMethodName("recipientIdentificationFailed", notification: theNotification)
    }

    @objc public func transactionResetCompleted(theNotification: NSNotification!) {
        dumpMethodName("transactionResetCompleted", notification: theNotification)
        sendMessage()
    }

    @objc public func transactionResetFailed(theNotification: NSNotification!) {
        dumpMethodName("transactionResetFailed", notification: theNotification)
    }
}

extension SmtpSend: CWServiceClient {
    @objc public func authenticationCompleted(theNotification: NSNotification!) {
        dumpMethodName("authenticationCompleted", notification: theNotification)
        smtp.reset()
    }

    @objc public func authenticationFailed(theNotification: NSNotification!) {
        dumpMethodName("authenticationFailed", notification: theNotification)
    }

    @objc public func connectionEstablished(theNotification: NSNotification!) {
        dumpMethodName("connectionEstablished", notification: theNotification)
    }

    @objc public func connectionLost(theNotification: NSNotification!) {
        dumpMethodName("connectionLost", notification: theNotification)
    }

    @objc public func connectionTerminated(theNotification: NSNotification!) {
        dumpMethodName("connectionTerminated", notification: theNotification)
    }

    @objc public func connectionTimedOut(theNotification: NSNotification!) {
        dumpMethodName("connectionTimedOut", notification: theNotification)
    }

    @objc public func requestCancelled(theNotification: NSNotification!) {
        dumpMethodName("requestCancelled", notification: theNotification)
    }

    @objc public func serviceInitialized(theNotification: NSNotification!) {
        dumpMethodName("serviceInitialized", notification: theNotification)
        dispatch_async(dispatch_get_main_queue(), {
            if self.connectInfo.smtpTransport == ConnectionTransport.StartTLS &&
                !self.smtpStatus.haveStartedTLS {
                self.smtpStatus.haveStartedTLS = true
                self.smtp.startTLS()
            } else {
                let password = KeyChain.getPassword(self.connectInfo.email,
                    serverType: Account.AccountType.Smtp.asString())
                self.smtp.authenticate(self.connectInfo.getSmtpUsername(),
                    password: password,
                    mechanism: self.connectInfo.smtpAuthMethod)
            }
        })
    }

    @objc public func serviceReconnected(theNotification: NSNotification!) {
        dumpMethodName("serviceReconnected", notification: theNotification)
    }

}