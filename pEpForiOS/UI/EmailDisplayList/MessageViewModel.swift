//
//  MessageViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 13/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class MessageViewModel {

    static var maxBodyPreviewCharacters = 120


    var senderContactImage: UIImage?
    var ratingImage: UIImage?
    var showAttchmentIcon: Bool = false
    let from: String
    let address: String
    let subject: String
    let bodyPeek: String
    var isFlagged: Bool = false
    var isSeen: Bool = false
    var dateText: String
    var messageCount: Int
    var profilePictureComposer: ProfilePictureComposer
    var body: NSAttributedString {
            return getBodyMessage()
    }
    var message: Message

    init(with message: Message) {
        showAttchmentIcon = message.attachments.count > 0
        from = (message.from ?? Identity(address: "unknown@unknown.com")).userNameOrAddress
        address =  MessageViewModel.address(at: message.parent, from: message)
        subject = message.shortMessage ?? ""
        isFlagged = message.imapFlags?.flagged ?? false
        isSeen = message.imapFlags?.seen ?? false
        dateText =  (message.sent ?? Date()).smartString()
        messageCount = message.numberOfMessagesInThread()
        profilePictureComposer = PepProfilePictureComposer()
        bodyPeek = MessageViewModel.getSummary(fromMessage: message)
        self.message = message
    }

    private class func address(at folder: Folder?, from message: Message) -> String {
        guard let folder = folder else {
            return ""
        }
        switch folder.folderType {
        case .all: fallthrough
        case .archive: fallthrough
        case .spam: fallthrough
        case .trash: fallthrough
        case .flagged: fallthrough
        case .inbox: fallthrough
        case .normal:
            return (message.from ?? Identity(address: "unknown@unknown.com")).userNameOrAddress
        case .drafts: fallthrough
        case .sent:
            return message.to.first?.userNameOrAddress ?? ""
        }
    }

    private class func getSummary(fromMessage msg: Message) -> String {
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

    func getProfilePicture(completion: @escaping (UIImage?)->()){
        profilePictureComposer.getProfilePicture(for: from, completion: completion)
    }

    func getSecurityBadge(completion: @escaping (UIImage?) ->()) {
        profilePictureComposer.getSecurityBadge(for: message, completion: completion)
    }


    func getBodyMessage() -> NSMutableAttributedString {
        let finalText = NSMutableAttributedString()
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: PEP_rating_under_attack)
            let messageString = String(
                format: NSLocalizedString(
                    "\n%@\n\n%@\n\n%@\n\nAttachments are disabled.\n\n",
                    comment: "Disabled attachments for a message with status 'under attack'. Placeholders: title, explanation, suggestion."),
                status.title, status.explanation, status.suggestion)
            finalText.bold(messageString)
        }

        if let text = message.longMessage?.trimmedWhiteSpace() {
            finalText.normal(text)
        } else if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
            finalText.normal(text)
        } else if message.pEpRating().isUnDecryptable() {
            finalText.normal(NSLocalizedString(
                "This message could not be decrypted.",
                comment: "content that is shown for undecryptable messages"))
        } else {
            // Empty body
            finalText.normal("")
        }
        return finalText
    }

    func getTo()->NSMutableAttributedString {
        let attributed = NSMutableAttributedString(
            string: NSLocalizedString("To:", comment: "Compose field title"))
        let attributes = [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15.0),
            NSAttributedStringKey.foregroundColor: UIColor.lightGray
        ]
        var temp: [String] = []
        message.allRecipients.forEach { (recepient) in
            let recepient = recepient.address
            temp.append(recepient)
        }
        attributed.append(NSAttributedString(string: temp.joined(separator: ", "), attributes: attributes))
        return attributed
    }


}
    
