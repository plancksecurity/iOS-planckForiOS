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
    let filename: String
    let contentType: String
    let data: NSData
}

/**
 Converts a given IMessage to a (non-core-data) attachment object.
 */
public class MessageToAttachmentOperation: ConcurrentBaseOperation {
    let comp = "MessageToAttachmentOperation"

    /** The core data objectID */
    let messageID: NSManagedObjectID

    let coreDataUtil: ICoreDataUtil

    var attachment: SimpleAttachment?

    public init(message: IMessage, coreDataUtil: ICoreDataUtil) {
        self.messageID = (message as! Message).objectID
        self.coreDataUtil = coreDataUtil
    }

    public override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performBlock() {
            self.doWork(privateMOC)
            self.markAsFinished()
        }
    }

    func doWork(privateMOC: NSManagedObjectContext) {
        guard let message = privateMOC.objectWithID(self.messageID) as? IMessage else {
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
            filename: "mail.eml", contentType: "message/rfc822", data: data)
    }

    func errorMessage(localizedMessage: String, logMessage: String) {
        addError(Constants.errorOperationFailed(comp, errorMessage: localizedMessage))
        Log.errorComponent(comp, errorString: logMessage)
    }
}