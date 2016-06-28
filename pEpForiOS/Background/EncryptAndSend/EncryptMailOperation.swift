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

    let encryptionData: EncryptionData

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override public func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            guard let message = privateMOC.objectWithID(self.encryptionData.messageID) as? Message
                else {
                    Log.warn(self.comp, "Need valid email")
                    return
            }
            let pepMailOrig = PEPUtil.pepMail(message)
            let session = PEPSession.init()
            var mailsToSend: [PEPMail] = []
            let (mailsToEncrypt, mailsNotToEncrypt) = session.bucketsForPEPMail(pepMailOrig)
            mailsToSend.appendContentsOf(mailsNotToEncrypt)

            for mail in mailsToEncrypt {
                var encryptedMail: NSDictionary? = nil
                session.encryptMessageDict(mail as [NSObject : AnyObject], extra: nil,
                    dest: &encryptedMail)
                if let mail = encryptedMail {
                    mailsToSend.append(mail as PEPMail)
                } else {
                    Log.warn(self.comp, "Could not encrypt message")
                }
            }
            self.encryptionData.mailsToSend = mailsToSend
        })
    }
}