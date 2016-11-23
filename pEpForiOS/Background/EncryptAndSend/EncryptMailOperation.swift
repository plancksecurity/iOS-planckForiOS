//
//  EncryptMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Encrypts a message. Suitable for chaining with other operations that operate
 on `EncryptionData`. Will encrypt the message also for oneself, for storing in the
 sent folder.
 */
open class EncryptMailOperation: EncryptBaseOperation {
    public init(encryptionData: EncryptionData) {
        super.init(comp: "EncryptMailOperation", encryptionData: encryptionData)
    }

    override open func main() {
        privateMOC.perform({
            self.encryptMessage(context: self.privateMOC)
        })
    }

    func encryptMessage(context: NSManagedObjectContext) {
        guard let message = fetchMessage(context: context) else {
            return
        }
        guard let account = message.parent?.account else {
                self.addError(Constants.errorCannotFindAccount(component: comp))
                return
        }
        let pepMailOrig = PEPUtil.pEp(mail: message, outgoing: encryptionData.outgoing)
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
            let (mail, error) = PEPUtil.checkPepStatus(self.comp, status: pepStatus,
                                                       encryptedMail: encryptedMail)
            if let er = error {
                addError(er)
                markAsFinished()
                return
            }
            if let m = mail {
                mailsToSend.append(m as! PEPMail)
            }
        }
        self.encryptionData.mailsToSend = mailsToSend

        // Encrypt mail to yourself
        let ident = PEPUtil.identity(account: account)
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
    }
}
