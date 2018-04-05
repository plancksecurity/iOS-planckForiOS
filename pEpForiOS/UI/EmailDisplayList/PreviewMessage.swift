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
    let uid: UInt
    private let uuid: MessageID
    private let address: String
    private let parentFolderName: String
    var pEpRating: Int
    let hasAttachments: Bool
    let from: Identity
    let to: String
    let subject: String
    var bodyPeek: String
    var isFlagged = false
    var isSeen = false
    let dateSent: Date

    var maxBodyPreviewCharacters = 120

    init(withMessage msg: Message) {
        if let rating = msg.pEpRatingInt, let sent = msg.sent, let saveFrom = msg.from {
            uuid = msg.uuid
            uid = msg.uid
            address = msg.parent.account.user.address
            parentFolderName = msg.parent.name
            pEpRating = rating
            hasAttachments = msg.attachments.count > 0
            from = saveFrom
            to = msg.to.first?.userNameOrAddress ?? ""
            subject = msg.shortMessage ?? ""
            isFlagged = msg.imapFlags?.flagged ?? false
            isSeen = msg.imapFlags?.seen ?? false
            dateSent = sent
            bodyPeek = ""
            bodyPeek = displayBody(fromMessage: msg)
        } else {
            //this block is only to avoid returning an Optional (init?)
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have those values here")
            // Required field are missing. Should never happen. Return dummy data
            uuid = msg.uuid
            uid = 0
            address = msg.parent.account.user.address
            parentFolderName = msg.parent.name
            pEpRating = 0
            hasAttachments = msg.attachments.count > 0
            from = Identity(address: "")
            to = msg.to.first?.userNameOrAddress ?? ""
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
            // Limit the size of HTML to parse
            // That might result in a messy preview but valid messages use to offer a plaintext
            // version while certain spam mails have thousands of lines of invalid HTML, causing
            // the parser to take minutes to parse one message.
            let factorHtmlTags = 3
            let numChars = maxBodyPreviewCharacters * factorHtmlTags
            let truncatedHtml = html.prefix(ofLength: numChars)
            body = truncatedHtml.extractTextFromHTML()
            body = body?.replaceNewLinesWith(" ").trimmedWhiteSpace()
        }
        guard let saveBody = body else {
            return ""
        }

        let result: String
        if saveBody.count <= maxBodyPreviewCharacters {
            result = saveBody
        } else {
            let endIndex = saveBody.index(saveBody.startIndex, offsetBy: maxBodyPreviewCharacters)
            result = String(saveBody[..<endIndex])
        }
        return result
    }

    public func message() -> Message? {
        guard let msg = Message.by(uid: uid,
                                   uuid: uuid,
                                   folderName: parentFolderName,
                                   accountAddress: address)
            else {
                // The model has changed.
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
            lhs.uid == rhs.uid &&
            lhs.parentFolderName == rhs.parentFolderName &&
            lhs.address == rhs.address
    }
    
    static func ==(lhs: PreviewMessage, rhs: Message) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.uid == rhs.uid &&
            lhs.parentFolderName == rhs.parent.name &&
            lhs.address == rhs.parent.account.user.address
    }
}
