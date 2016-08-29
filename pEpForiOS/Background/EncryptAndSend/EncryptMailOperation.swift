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
public class EncryptMailOperation: ConcurrentBaseOperation {
    let comp = "EncryptMailOperation"

    /**
     All the parameters for the operation come from here.
     */
    let encryptionData: EncryptionData

    lazy var privateMOC: NSManagedObjectContext =
        self.encryptionData.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override public func main() {
        privateMOC.performBlock({
            guard let account = self.model.accountByEmail(
                self.encryptionData.accountEmail) else {
                    self.addError(Constants.errorCannotFindAccountForEmail(
                        self.comp, email: self.encryptionData.accountEmail))
                    return
            }
            guard let message = self.privateMOC.objectWithID(
                self.encryptionData.coreDataMessageID) as? Message else {
                    let error = Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:
                        NSLocalizedString("Email for encryption could not be accessed",
                            comment: "Error message when message to encrypt could not be found."))
                    self.addError(error)
                    Log.errorComponent(self.comp, error: Constants.errorInvalidParameter(
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
            allMails.appendContentsOf(mailsUnencrypted)

            for origMail in allMails {
                var encryptedMail: NSDictionary? = nil
                let pepStatus = session.encryptMessageDict(
                    origMail as [NSObject : AnyObject], extra: nil,
                    dest: &encryptedMail)
                if let mail = self.checkPepStatus(pepStatus, encryptedMail: encryptedMail) {
                    mailsToSend.append(mail as PEPMail)
                }
            }
            self.encryptionData.mailsToSend = mailsToSend

            // Encrypt mail to yourself
            let ident = PEPUtil.identityFromAccount(account, isMyself: true)
                as [NSObject : AnyObject]
            var encryptedMail: NSDictionary? = nil
            let status = session.encryptMessageDict(
                pepMailOrig, identity: ident, dest: &encryptedMail)
            if let mail = self.checkPepStatus(status, encryptedMail: encryptedMail) {
                self.encryptionData.mailEncryptedForSelf = mail as PEPMail
            }

            self.markAsFinished()
        })
    }

    /**
     Checks the given pEp status and the given encrypted mail for errors and
     logs them.
     - Returns: The encrypted mail, which might be nil.
     */
    func checkPepStatus(
        status: PEP_STATUS, encryptedMail: NSDictionary?) -> NSDictionary? {
        if encryptedMail != nil && status == PEP_UNENCRYPTED {
            // Don't interpret that as an error
            return encryptedMail
        }
        if encryptedMail == nil || status != PEP_STATUS_OK {
            let error = Constants.errorEncryption(self.comp, status: status)
            self.addError(error)
            Log.errorComponent(self.comp, error: Constants.errorInvalidParameter(
                self.comp,
                errorMessage: "Could not encrypt message, pEp status \(status)"))
        }
        return encryptedMail
    }
}