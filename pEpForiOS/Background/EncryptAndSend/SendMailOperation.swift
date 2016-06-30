//
//  SendMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class SendMailOperation: ConcurrentBaseOperation {
    let comp = "SendMailOperation"

    /**
     All the parameters for the operation come from here.
     `mailsToSend` denotes the (pEp) mails that are about to be sent.
     */
    let encryptionData: EncryptionData

    /**
     Store the SMTP object so that it does not get collected away.
     */
    var smtpSend: SmtpSend!

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override public func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        var connectInfo: ConnectInfo? = nil
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            guard let account = model.accountByEmail(self.encryptionData.accountEmail) else {
                self.errors.append(Constants.errorInvalidParameter(
                    self.comp,
                    errorMessage: String.localizedStringWithFormat(
                        NSLocalizedString("Could not get account by email: '%s'",
                            comment: "Error message when account could not be retrieved"),
                        self.encryptionData.accountEmail)))
                Log.error(self.comp, error: Constants.errorInvalidParameter(
                    self.comp,
                    errorMessage:
                    "Could not get account by email: \(self.encryptionData.accountEmail)"))
                return
            }
            connectInfo = account.connectInfo
        })
        if let ci = connectInfo {
            smtpSend = encryptionData.connectionManager.smtpConnection(ci)
            smtpSend.delegate = self
            smtpSend.start()
        } else {
            markAsFinished()
        }
    }
}

extension SendMailOperation: SmtpSendDelegate {
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
}