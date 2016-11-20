//
//  MessageToAttachmentOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 Converts a given Message to a (non-core-data) attachment object.
 */
open class MessageToAttachmentOperation: BaseOperation {
    let comp = "MessageToAttachmentOperation"

    let message: Message

    var attachment: Attachment?

    public init(message: Message) {
        self.message = message
    }

    open override func main() {
        let pantMail = PEPUtil.pantomimeMail(message: message)
        guard let data = pantMail.dataValue() else {
            errorMessage(NSLocalizedString(
                "Could not get data from forwarded message", comment: "Internal error"),
                         logMessage: "Could not get data from forwarded message")
            return
        }
        attachment = Attachment.create(data: data, mimeType: Constants.attachedEmailMimeType,
                                       fileName: "mail.eml")
    }

    func errorMessage(_ localizedMessage: String, logMessage: String) {
        addError(Constants.errorOperationFailed(comp, errorMessage: localizedMessage))
        Log.error(component: comp, errorString: logMessage)
    }
}
