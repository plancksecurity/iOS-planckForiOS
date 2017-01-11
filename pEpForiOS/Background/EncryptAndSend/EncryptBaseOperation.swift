//
//  EncryptBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class EncryptBaseOperation: ConcurrentBaseOperation {
    /**
     All the parameters for the operation come from here.
     */
    let encryptionData: EncryptionData

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    func fetchMessage(context: NSManagedObjectContext) -> CdMessage? {
        guard let message = context.object(with: encryptionData.messageID) as? CdMessage else {
            let error = Constants.errorInvalidParameter(
                self.comp,
                errorMessage:
                NSLocalizedString("Message for encryption could not be accessed",
                                  comment: "Error message when message to encrypt could not be found."))
            self.addError(error)
            Log.error(component: self.comp, error: Constants.errorInvalidParameter(
                self.comp,
                errorMessage:"Message for encryption could not be accessed"))
            return nil
        }
        return message
    }
}
