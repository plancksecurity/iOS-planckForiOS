//
//  EncryptMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Encrypts messages. Suitable for chaining with other operations that operate on `EncryptionData`.
 */
public class EncryptMailOperation: BaseOperation {
    let comp = "EncryptMailOperation"

    /**
     All the parameters for the operation come from here.
     */
    let encryptionData: EncryptionData

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override public func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            guard let message = privateMOC.objectWithID(
                self.encryptionData.coreDataMessageID) as? Message
                else {
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

            // They should all get the pEp treatment, even though they don't all get encrypted.
            // E.g., for receiving the public key as attachment.
            var allMails = mailsToEncrypt
            allMails.appendContentsOf(mailsUnencrypted)

            for origMail in allMails {
                var encryptedMail: NSDictionary? = nil
                session.encryptMessageDict(origMail as [NSObject : AnyObject], extra: nil,
                    dest: &encryptedMail)
                if let mail = encryptedMail {
                    mailsToSend.append(mail as PEPMail)
                } else {
                    let error = Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:
                        NSLocalizedString("Could not encrypt message",
                            comment: "Error message when the engine failed to encrypt a message."))
                    self.addError(error)
                    Log.errorComponent(self.comp, error: Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage: "Could not encrypt message"))
                }
            }
            self.encryptionData.mailsToSend = mailsToSend
        })
    }
}