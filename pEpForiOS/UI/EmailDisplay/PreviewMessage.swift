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
    var pEpRating: Int
    let hasAttachments: Bool
    let from: Identity
    let subject: String
    var bodyPeek: String
    var isFlagged: Bool = false
    var isSeen: Bool = false
    let dateSent: Date

    var maxBodyPreviewCharacters = 120

    init(withMessage msg: Message) {
        if let rating = msg.pEpRatingInt,
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
            isFlagged = msg.imapFlags?.flagged ?? false
            isSeen = msg.imapFlags?.seen ?? false
            dateSent = sent
            bodyPeek = ""
            bodyPeek = displayBody(fromMessage: msg)
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


    private func displayBody(fromMessage msg: Message) -> String {
        var body: String?
        if let text = msg.longMessage {
            body = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
        } else if let html = msg.longMessageFormatted {
            body = html.extractTextFromHTML()
            body = body?.replaceNewLinesWith(" ").trimmedWhiteSpace()
        }
        guard let saveBody = body else {
            return ""
        }

        let result: String
        if saveBody.characters.count <= maxBodyPreviewCharacters {
            result = saveBody
        } else {
            let endIndex = saveBody.index(saveBody.startIndex, offsetBy: maxBodyPreviewCharacters)
            result = String(saveBody[..<endIndex])
        }
        return result
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

    public func flagsDiffer(previewMessage pvMsg: PreviewMessage) -> Bool {
        if self != pvMsg {
            return true
        }
        return self.isFlagged != pvMsg.isFlagged || self.isSeen != pvMsg.isSeen
    }

    static func ==(lhs: PreviewMessage, rhs: PreviewMessage) -> Bool {
        return lhs.uuid == rhs.uuid &&
        lhs.parentFolderName == rhs.parentFolderName &&
        lhs.address == rhs.address
    }

    static func ==(lhs: PreviewMessage, rhs: Message) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.parentFolderName == rhs.parent.name &&
            lhs.address == rhs.parent.account.user.address
    }
}
