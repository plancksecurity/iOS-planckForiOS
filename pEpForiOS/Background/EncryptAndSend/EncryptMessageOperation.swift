//
//  EncryptMessageOperation.swift
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
open class EncryptMessageOperation: EncryptBaseOperation {
    public init(encryptionData: EncryptionData) {
        super.init(comp: "EncryptMessageOperation", encryptionData: encryptionData)
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
        let pepMessageOrig = PEPUtil.pEp(cdMessage: message, outgoing: encryptionData.outgoing)
        let session = PEPSession.init()
        var messagesToSend: [PEPMessage] = []
        let (messagesToEncrypt, mailsUnencrypted) = session.bucketsForPEPMessage(pepMessageOrig)

        // They should all get the pEp treatment, even though they don't all get
        // encrypted. E.g., for receiving the public key as attachment.
        var allMessages = messagesToEncrypt
        allMessages.append(contentsOf: mailsUnencrypted)

        for origMessage in allMessages {
            var encryptedMessage: NSDictionary? = nil
            let pepStatus = session.encryptMessageDict(
                origMessage, extra: nil,
                dest: &encryptedMessage)
            let (msg, error) = PEPUtil.check(comp: self.comp, status: pepStatus,
                                                       encryptedMessage: encryptedMessage)
            if let er = error {
                addError(er)
                markAsFinished()
                return
            }
            if let m = msg {
                messagesToSend.append(m as! PEPMessage)
            }
        }
        self.encryptionData.messagesToSend = messagesToSend

        // Encrypt message to yourself
        let ident = PEPUtil.identity(account: account)
        var encryptedMail: NSDictionary? = nil
        let status = session.encryptMessageDict(
            pepMessageOrig, identity: ident,
            dest: &encryptedMail)
        let (msg, _) = PEPUtil.check(comp: self.comp, status: status,
                                               encryptedMessage: encryptedMail)
        if let m = msg {
            self.encryptionData.messageEncryptedForSelf = m as? PEPMessage
        }

        self.markAsFinished()
    }
}
