//
//  MessageViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 13/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class MessageViewModel: CustomDebugStringConvertible {

    static var maxBodyPreviewCharacters = 120
    let queue = OperationQueue()

    let uid: UInt
    private let uuid: MessageID
    private let address: String
    private let parentFolderName: String
    private let accountAddress: String

    let identity:Identity
    let dateSent: Date
    let longMessageFormatted: String?

    var senderContactImage: UIImage?
    var ratingImage: UIImage?
    var showAttchmentIcon: Bool = false
    let from: String
    let subject: String
    var isFlagged: Bool = false
    var isSeen: Bool = false
    var dateText: String
    var profilePictureComposer: ProfilePictureComposer
    var body: NSAttributedString {
            return getBodyMessage()
    }

    var displayedIdentity: String

    internal var internalMessageCount: Int? = nil
    internal var internalBoddyPeek: String? = nil

    private var bodyPeek: String? {
        didSet {
            informIfBodyPeekCompleted()
        }
    }

    var bodyPeekCompletion: ((String) -> ())? = nil {
        didSet {
            guard bodyPeekCompletion != nil else {
                return
            }
            informIfBodyPeekCompleted()
        }
    }

    //Only to use internally, external use should call public message()
    private var internalMessage: Message

    init(with message: Message) {
        internalMessage = message
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 3

        uid = message.uid
        uuid = message.uuid
        parentFolderName = message.parent.name
        accountAddress = message.parent.account.user.address

        longMessageFormatted = message.longMessageFormatted
        dateSent = message.sent ?? Date()

        showAttchmentIcon = message.attachments.count > 0
        identity = (message.from ?? Identity(address: "unknown@unknown.com"))
        from = (message.from ?? Identity(address: "unknown@unknown.com")).userNameOrAddress
        address =  MessageViewModel.address(at: message.parent, from: message)
        subject = message.shortMessage ?? ""
        isFlagged = message.imapFlags?.flagged ?? false
        isSeen = message.imapFlags?.seen ?? false
        dateText =  (message.sent ?? Date()).smartString()
        profilePictureComposer = PepProfilePictureComposer()
        displayedIdentity = MessageViewModel.getDisplayedIdentity(for: message)
        setBodyPeek(for: message)
    }

    static private func getDisplayedIdentity(for message: Message)-> String{
        if (message.parent.folderType == .sent
            || message.parent.folderType == .drafts){
            var identities: [String] = []
            message.allRecipients.forEach { (recepient) in
                let recepient = recepient.userNameOrAddress
                identities.append(recepient)
            }
            return identities.joined(separator: ", ")
        } else {
            return message.from?.userNameOrAddress ?? ""

        }
    }

    public func flagsDiffer(from messageViewModel: MessageViewModel) -> Bool {
        if self != messageViewModel {
            return true
        }
        return self.isFlagged != messageViewModel.isFlagged || self.isSeen != messageViewModel.isSeen
    }

    func unsubscribeForUpdates() {
        cancelLoad()
    }

    func cancelLoad() {
        queue.cancelAllOperations()
    }

    func setBodyPeek(for message:Message) {
        if let bodyPeek = internalBoddyPeek {
           self.bodyPeek = bodyPeek
        } else {
            let operation = bodyPeekPrefetch(for: message) { bodyPeek in
                self.bodyPeek = bodyPeek
            }
            if(!operation.isFinished){
                queue.addOperation(operation)
            }
        }
    }

    func informIfBodyPeekCompleted() {
        guard let bodyPeek = bodyPeek else {
            return
        }
        bodyPeekCompletion?(bodyPeek)
        bodyPeekCompletion = nil
    }

    func messageCount(completion: @escaping (Int)->()) {
        if let messageCount = internalMessageCount {
            completion(messageCount)
        } else {
            let operation =  messageCountPrefetch { count in
                completion(count)
            }
            if(!operation.isFinished){
                queue.addOperation(operation)
            }
        }
    }

    private class func address(at folder: Folder?, from message: Message) -> String {
        guard let folder = folder else {
            return ""
        }
        switch folder.folderType {
        case .all, .archive, .spam, .trash, .flagged, .inbox, .normal:
            return (message.from ?? Identity(address: "unknown@unknown.com")).userNameOrAddress
        case .drafts, .sent:
            return message.to.first?.userNameOrAddress ?? ""
        }
    }

    internal class func getSummary(fromMessage msg: Message) -> String {
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

    func appendInlinedAttachmentsPlainText(to text: String) -> String {
        var result = text
        guard let message = message() else {
            return result
        }
        let inlinedText = message.inlinedTextAttachments()
        for inlinedTextAttachment in inlinedText {
            guard
                let data = inlinedTextAttachment.data,
                let inlinedText = String(data: data, encoding: .utf8) else {
                    continue
            }
            result = append(appendText: inlinedText, to: result)
        }
        return result
    }

    private func append(appendText: String, to body: String) -> String {
        var result = body
        let replacee = result.contains(find: "</body>") ? "</body>" : "</html>"
        if result.contains(find: replacee) {
            result = result.replacingOccurrences(of: replacee, with: appendText + replacee)
        } else {
            result += "\n" + appendText
        }
        return result
    }

    public func message() -> Message? {
        guard let msg = Message.by(uid: uid,
                                   uuid: uuid,
                                   folderName: parentFolderName,
                                   accountAddress: accountAddress)
            else {
                // The model has changed.
                return nil
        }
        return msg
    }

    func getProfilePicture(completion: @escaping (UIImage?)->()){
        profilePictureComposer.getProfilePicture(for: identity, completion: completion)
    }

    func getSecurityBadge(completion: @escaping (UIImage?) ->()) {
        let operation = getSecurityBadgeOperation(completion: completion)
        queue.addOperation(operation)
    }

    func getBodyMessage() -> NSMutableAttributedString {
        guard let message = message() else {
            //crash and return nonsense
            return NSMutableAttributedString()
        }
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
        message()?.allRecipients.forEach { (recepient) in
            let recepient = recepient.address
            temp.append(recepient)
        }
        attributed.append(NSAttributedString(string: temp.joined(separator: ", "), attributes: attributes))
        return attributed
    }

    public var debugDescription: String {
        return "<MessageViewModel |\(messageIdentifier)| |\(internalMessage.longMessage?.prefix(3) ?? "nil")|>"
    }
}

extension MessageViewModel: Equatable {
    static func ==(lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.uid == rhs.uid &&
            lhs.parentFolderName == rhs.parentFolderName &&
            lhs.accountAddress == rhs.accountAddress
    }
}

extension MessageViewModel: MessageIdentitfying {
    var messageIdentifier: MessageID {
        return uuid
    }
}
