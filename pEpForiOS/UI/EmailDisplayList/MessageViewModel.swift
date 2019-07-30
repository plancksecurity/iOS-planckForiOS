//
//  MessageViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 13/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox
import PEPObjCAdapterFramework

class MessageViewModel: CustomDebugStringConvertible {
    static fileprivate var maxBodyPreviewCharacters = 120

    private var queue: OperationQueue
    private var runningOperations = [Operation]()

    let uid: Int
    private let uuid: MessageID
    private let parentFolderName: String
    private let accountAddress: String
    private let displayedImageIdentity: Identity

    let identity:Identity
    let dateSent: Date
    let longMessageFormatted: String?
    var senderContactImage: UIImage?
    private var ratingImage: UIImage?
    var showAttchmentIcon: Bool = false
    let from: String
    let subject: String
    var isFlagged: Bool = false
    var isSeen: Bool = false
    var dateText: String
    var profilePictureComposer: ProfilePictureComposerProtocol
    var body: NSAttributedString {
            return getBodyMessage()
    }
    var displayedUsername: String
    var internalBoddyPeek: String? = nil
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

    required init(with message: Message, queue: OperationQueue) {
        self.queue = queue

        uid = message.uid
        uuid = message.uuid
        parentFolderName = message.parent.name
        accountAddress = message.parent.account.user.address

        longMessageFormatted = message.longMessageFormatted
        dateSent = message.sent ?? Date()

        showAttchmentIcon = message.viewableAttachments().count > 0
        identity = (message.from ?? Identity(address: "unknown@unknown.com"))
        from = (message.from ?? Identity(address: "unknown@unknown.com")).userNameOrAddress
        displayedImageIdentity =  MessageViewModel.identityForImage(from: message)
        subject = message.shortMessage ?? ""
        isFlagged = message.imapFlags.flagged
        isSeen = message.imapFlags.seen
        dateText =  (message.sent ?? Date()).smartString()
        profilePictureComposer = PepProfilePictureComposer()
        displayedUsername = MessageViewModel.getDisplayedUsername(for: message)
        setBodyPeek(for: message)
    }

    static private func getDisplayedUsername(for message: Message) -> String {
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
        cancelAllBackgroundOperations()
    }

    private func cancelAllBackgroundOperations() {
        runningOperations.forEach { $0.cancel() }
    }

    private func setBodyPeek(for message:Message) {
        if let bodyPeek = internalBoddyPeek {
            self.bodyPeek = bodyPeek
        } else {
            let operation = getBodyPeekOperation(for: message) { [weak self] bodyPeek in
                // It's valid to loose self here. The view can dissappear @ any time.
                self?.bodyPeek = bodyPeek
            }
            addToRunningOperations(operation)
        }
    }

    private func informIfBodyPeekCompleted() {
        guard let bodyPeek = bodyPeek else {
            return
        }
        bodyPeekCompletion?(bodyPeek)
        bodyPeekCompletion = nil
    }

    // Message threading is not supported. Let's keep it for now. It might be helpful for
    // reimplementing.
//    var internalMessageCount: Int? = nil
//    func messageCount(completion: @escaping (Int)->()) {
//        if let messageCount = internalMessageCount {
//            completion(messageCount)
//        } else {
//            let operation =  getMessageCountOperation { count in
//                completion(count)
//            }
//            if(!operation.isFinished){
//                addToRunningOperations(operation)
//            }
//        }
//    }

    private class func identityForImage(from message: Message) -> Identity {
        switch message.parent.folderType {
        case .all, .archive, .spam, .trash, .flagged, .inbox, .normal:
            return (message.from ?? Identity(address: "unknown@unknown.com"))
        case .drafts, .sent, .outbox:
            return message.to.first ?? Identity(address: "unknown@unknown.com")
        }
    }

    class func getSummary(fromMessage msg: Message) -> String {
        var body: String?
        if var text = msg.longMessage {
            text = text.stringCleanedFromNSAttributedStingAttributes()
                .replaceNewLinesWith(" ")
                .trimmed()
            body = text
            //        } else if let html = safeMsg.longMessageFormatted {
        } else if let html = msg.longMessageFormatted {
            // Limit the size of HTML to parse
            // That might result in a messy preview but valid messages use to offer a plaintext
            // version while certain spam mails have thousands of lines of invalid HTML, causing
            // the parser to take minutes to parse one message.
            let factorHtmlTags = 3
            let numChars = maxBodyPreviewCharacters * factorHtmlTags
            let truncatedHtml = html.prefix(ofLength: numChars)
            body = truncatedHtml.extractTextFromHTML()

            //IOS-1347:
            // We might want to cleans when displaying instead of when saving.
            // Waiting for details. See IOS-1347.

            body = body?.replaceNewLinesWith(" ").trimmed()
            //            }
        }
        guard let safeBody = body else {
            return ""
        }

        let result: String
        if safeBody.count <= maxBodyPreviewCharacters {
            result = safeBody
        } else {
            let endIndex = safeBody.index(safeBody.startIndex, offsetBy: maxBodyPreviewCharacters)
            result = String(safeBody[..<endIndex])
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

    func getProfilePicture(completion: @escaping (UIImage?) -> ()) {
        let operation = getProfilePictureOperation(completion: completion)
        addToRunningOperations(operation)
    }

    func getSecurityBadge(completion: @escaping (UIImage?) ->()) {
        let operation = getSecurityBadgeOperation(completion: completion)
        addToRunningOperations(operation)
    }

    func getBodyMessage() -> NSMutableAttributedString {
        guard let message = message() else {
            //crash and return nonsense
            return NSMutableAttributedString()
        }
        let finalText = NSMutableAttributedString()
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: .underAttack)
            let messageString = String.localizedStringWithFormat(
                NSLocalizedString(
                    "\n%1$@\n\n%2$@\n\n%3$@\n\nAttachments are disabled.\n\n",
                    comment: "Disabled attachments for a message with status 'under attack'. Placeholders: Title, explanation, suggestion."),
                status.title, status.explanation, status.suggestion)
            finalText.bold(messageString)
        }

        if let text = message.longMessage?.trimmed() {
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
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0),
            NSAttributedString.Key.foregroundColor: UIColor.lightGray
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
        return "<MessageViewModel |\(uuid)| |\(longMessageFormatted?.prefix(3) ?? "nil")|>"
    }
}

extension MessageViewModel: Equatable {
    static func ==(lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        let oneIsAFakeMessage =
            lhs.uid == Message.uidFakeResponsivenes ||
            rhs.uid == Message.uidFakeResponsivenes
        return lhs.uuid == rhs.uuid &&
            // We consider two messages with different UIDs as equal if one is the fake message
            // of the other.
            (oneIsAFakeMessage || (lhs.uid == rhs.uid)) &&
            lhs.parentFolderName == rhs.parentFolderName &&
            lhs.accountAddress == rhs.accountAddress
    }
}

// MARK: Operations

extension MessageViewModel {

    private func addToRunningOperations(_ op: Operation) {
        runningOperations.append(op)
        queue.addOperation(op)
    }

    private func getBodyPeekOperation(for message: Message, completion: @escaping (String)->()) -> Operation {
        let session = Session()
        let safeMsg = message.safeForSession(session)

        let getBodyPeekOperation = SelfReferencingOperation { [weak self] operation in
            guard
                let operation = operation,
                !operation.isCancelled else {
                    return
            }
            guard let me = self else {
                return
            }
            session.performAndWait {
                guard !operation.isCancelled else {
                    return
                }
                let summary = MessageViewModel.getSummary(fromMessage: safeMsg)
                guard !operation.isCancelled else {
                    return
                }
                me.internalBoddyPeek = summary
                if(!operation.isCancelled){
                    DispatchQueue.main.async {
                        completion(summary)
                    }
                }
            }
        }
        return getBodyPeekOperation
    }

    private func getSecurityBadgeOperation(completion: @escaping (UIImage?) -> ()) -> Operation {
        let msg = message()
        let session = Session()
        guard let safeMsg = msg?.safeForSession(session) else {
            // return empty OP
            return Operation()
        }
        
        let getSecurityBadgeOperation = SelfReferencingOperation { [weak self] operation in
            guard let me = self else {
                return
            }

            session.performAndWait {
                guard let operation = operation, !operation.isCancelled else {
                    return
                }
                me.profilePictureComposer.securityBadge(for: safeMsg, completion: completion)
            }
        }
        return getSecurityBadgeOperation
    }

    private func getProfilePictureOperation(completion: @escaping (UIImage?) -> ())
        -> SelfReferencingOperation {

            let identitykey = IdentityImageTool.IdentityKey(identity: displayedImageIdentity)

            let getSecurityBadgeOperation = SelfReferencingOperation { [weak self] operation in
                guard let me = self else {
                    return
                }
                guard
                    let operation = operation,
                    !operation.isCancelled else {
                        return
                }
                me.profilePictureComposer.profilePicture(for: identitykey,
                                                         completion: completion)
            }
            return getSecurityBadgeOperation
    }
}
