//
//  EncryptMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

/**
 Encrypts a message. Suitable for chaining with other operations that operate
 on `EncryptionData`. Will encrypt the message also for oneself, for storing in the
 sent folder.
 */
open class EncryptMailOperation: ConcurrentBaseOperation {
    let comp = "EncryptMailOperation"

    /**
     All the parameters for the operation come from here.
     */
    let encryptionData: EncryptionData

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override open func main() {
        privateMOC.perform({
            guard let account = self.model.accountByEmail(
                self.encryptionData.accountEmail) else {
                    self.addError(Constants.errorCannotFindAccountForEmail(
                        self.comp, email: self.encryptionData.accountEmail))
                    return
            }
            guard let message = self.privateMOC.object(
                with: self.encryptionData.coreDataMessageID) as? CdMessage else {
                    let error = Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:
                        NSLocalizedString("Email for encryption could not be accessed",
                            comment: "Error message when message to encrypt could not be found."))
                    self.addError(error)
                    Log.error(component: self.comp, error: Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:"Email for encryption could not be accessed"))
                    return
            }
            let pepMailOrig = PEPUtil.pepMail(message)
            let session = PEPSession.init()
            var mailsToSend: [PEPMail] = []
            let (mailsToEncrypt, mailsUnencrypted) = session.bucketsForPEPMail(pepMailOrig)

            // They should all get the pEp treatment, even though they don't all get
            // encrypted. E.g., for receiving the public key as attachment.
            var allMails = mailsToEncrypt
            allMails.append(contentsOf: mailsUnencrypted)

            for origMail in allMails {
                var encryptedMail: NSDictionary? = nil
                let pepStatus = session.encryptMessageDict(
                    origMail, extra: nil,
                    dest: &encryptedMail)
                let (mail, _) = PEPUtil.checkPepStatus(self.comp, status: pepStatus,
                    encryptedMail: encryptedMail)
                if let m = mail {
                    mailsToSend.append(m as! PEPMail)
                }
            }
            self.encryptionData.mailsToSend = mailsToSend

            // Encrypt mail to yourself
            let ident = PEPUtil.identityFromAccount(account, isMyself: true)
            var encryptedMail: NSDictionary? = nil
            let status = session.encryptMessageDict(
                pepMailOrig, identity: ident as NSDictionary as! [AnyHashable:Any],
                dest: &encryptedMail)
            let (mail, _) = PEPUtil.checkPepStatus(self.comp, status: status,
                encryptedMail: encryptedMail)
            if let m = mail {
                self.encryptionData.mailEncryptedForSelf = m as? PEPMail
            }

            self.markAsFinished()
        })
    }
}
