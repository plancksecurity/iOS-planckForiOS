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
    let message: Message

    var attachment: Attachment?

    public init(parentName: String = #function, message: Message) {
        self.message = message
        super.init(parentName: parentName)
    }

    open override func main() {
        let pantMail = PEPUtil.pantomime(message: message)
        guard let data = pantMail.dataValue() else {
            errorMessage(logMessage: "Could not get data from forwarded message")
            return
        }
        attachment = Attachment.create(data: data, mimeType: Constants.attachedEmailMimeType,
                                       fileName: "mail.eml")
    }

    func errorMessage(logMessage: String) {
        addError(BackgroundError.GeneralError.operationFailed(info: comp))
        Log.error(component: comp, errorString: logMessage)
    }
}
