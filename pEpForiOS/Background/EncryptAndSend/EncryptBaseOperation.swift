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
    let comp: String

    /**
     All the parameters for the operation come from here.
     */
    let encryptionData: EncryptionData

    init(comp: String, encryptionData: EncryptionData) {
        self.comp = comp
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

    /**
     Indicates an error setting up the operation. For now, this is handled
     the same as any other error, but that might change.
     */
    func handleEntryError(_ error: NSError, message: String) {
        handleError(error, message: message)
    }

    func handleError(_ error: NSError, message: String) {
        addError(error)
        Log.error(component: comp, errorString: message, error: error)
        markAsFinished()
    }
}
