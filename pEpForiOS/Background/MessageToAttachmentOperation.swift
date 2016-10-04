//
//  MessageToAttachmentOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

/**
 Simple pojo for attachments.
 */
public struct SimpleAttachment {
    let filename: String?
    let contentType: String?
    let data: Data?
    let image: UIImage?
}

/**
 Converts a given IMessage to a (non-core-data) attachment object.
 */
open class MessageToAttachmentOperation: ConcurrentBaseOperation {
    let comp = "MessageToAttachmentOperation"

    /** The core data objectID */
    let messageID: NSManagedObjectID

    var attachment: SimpleAttachment?

    public init(message: IMessage, coreDataUtil: ICoreDataUtil) {
        self.messageID = (message as! Message).objectID
        super.init(coreDataUtil: coreDataUtil)
    }

    open override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.perform() {
            self.doWork(privateMOC)
            self.markAsFinished()
        }
    }

    func doWork(_ privateMOC: NSManagedObjectContext) {
        guard let message = privateMOC.object(with: self.messageID) as? IMessage else {
            errorMessage(NSLocalizedString(
                "Could not find message by objectID", comment: "Internal error"),
                         logMessage: "Could not find message by objectID")
            return
        }
        let pantMail = PEPUtil.pantomimeMailFromMessage(message)
        guard let data = pantMail.dataValue() else {
            errorMessage(NSLocalizedString(
                "Could not get data from forwarded message", comment: "Internal error"),
                         logMessage: "Could not get data from forwarded message")
            return
        }
        attachment = SimpleAttachment.init(
            filename: "mail.eml", contentType: "message/rfc822", data: data , image: nil)
    }

    func errorMessage(_ localizedMessage: String, logMessage: String) {
        addError(Constants.errorOperationFailed(comp, errorMessage: localizedMessage))
        Log.errorComponent(comp, errorString: logMessage)
    }
}
