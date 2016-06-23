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
class EncryptMailOperation: BaseOperation {
    let comp = "EncryptMailOperation"

    let encryptionData: EncryptionData

    init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            guard let message = privateMOC.objectWithID(self.encryptionData.messageID) as? Message
                else {
                    Log.warn(self.comp, "Need valid email")
                    return
            }
            let pepMailOrig = PEPUtil.pepMail(message)
            let session = PEPSession.init()
            let (unencrypted, encryptedBCC, pepMail) =
                session.filterOutSpecialReceiversForPEPMail(pepMailOrig)
        })
    }
}