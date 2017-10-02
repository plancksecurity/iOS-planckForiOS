//
//  PreviewMessage.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import UIKit

class PreviewMessage: Equatable {
    private let uuid: MessageID
    private let userId: String?
    private let address: String
    private let parentFolderName: String
    var senderImage: UIImage?
    var pEpRating: Int
    let hasAttachments: Bool
    let from: Identity
    let subject: String
    let bodyPeek: String
    var isFlagged: Bool = false
    var isSeen: Bool = false
    let dateSent: Date

    init(withMessage msg: Message) {
        if let rating = msg.pEpRatingInt,
            let nameOrAddress = msg.from?.userNameOrAddress,
            let sent = msg.sent,
            let saveFrom = msg.from{
            uuid = msg.uuid
            userId = msg.parent.account.user.userID
            address = msg.parent.account.user.address
            parentFolderName = msg.parent.name
            pEpRating = rating
            hasAttachments = msg.attachments.count > 0
            from = saveFrom
            subject = msg.shortMessage ?? ""
            bodyPeek = msg.longMessageFormatted ?? msg.longMessage ?? ""
            isFlagged = msg.imapFlags?.flagged ?? false
            isSeen = msg.imapFlags?.seen ?? false
            dateSent = sent
        } else {
            //this block is only to avoid init?
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have those values here")
            // Required field are missing. Should never happen. Return dummy data
            uuid = msg.uuid
            userId = nil
            address = msg.parent.account.user.address
            parentFolderName = msg.parent.name
            pEpRating = 0
            hasAttachments = msg.attachments.count > 0
            from = Identity(address: "")
            subject = msg.shortMessage ?? ""
            bodyPeek = msg.longMessageFormatted ?? msg.longMessage ?? ""
            isFlagged = msg.imapFlags?.flagged ?? false
            isSeen = msg.imapFlags?.seen ?? false
            dateSent = Date()
        }

    }

    public func message() -> Message? {
        guard let msg = Message.by(uuid: uuid,
                                   parentFolderName: parentFolderName,
                                   inAccountWithAddress: address)
            else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "A we must always have a corresponding message")
                return nil
        }
        return msg
    }

    static func ==(lhs: PreviewMessage, rhs: PreviewMessage) -> Bool {
        return lhs.uuid == rhs.uuid &&
        lhs.parentFolderName == rhs.parentFolderName &&
        lhs.address == rhs.address
    }
}
