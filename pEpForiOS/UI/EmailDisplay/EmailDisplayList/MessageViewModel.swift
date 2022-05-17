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

class MessageViewModel: CustomDebugStringConvertible {
    private static var maxBodyPreviewCharacters = 120

    private let queueForHeavyStuff: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        createe.name = "security.pep.MessageViewModel.queueForHeavyStuff"
        return createe
    }()

    private let message: Message
    private let uid: Int
    private let uuid: MessageID
    private let parentFolderName: String
    private let accountAddress: String
    private let displayedImageIdentity: Identity
    private let identity: Identity
    private let dateSent: Date
    private let longMessageFormatted: String?
    private let from: String
    private var profilePictureComposer: ProfilePictureComposerProtocol
    private var internalBoddyPeek: String? = nil
    private var bodyPeek: String? {
        didSet {
            informIfBodyPeekCompleted()
        }
    }

    public let subject: String
    public var isFlagged: Bool = false
    public var isSeen: Bool = false
    public var dateText: String
    public var showAttchmentIcon: Bool = false
    public var senderContactImage: UIImage?
    public var displayedUsername: String
    public var bodyPeekCompletion: ((String) -> ())? = nil {
        didSet {
            guard bodyPeekCompletion != nil else {
                return
            }
            informIfBodyPeekCompleted()
        }
    }

    required init(with message: Message) {
        self.message = message

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
        isFlagged = message.imapFlags.flagged || message.imapUIFlags?.flagged ?? false
        isSeen = message.imapFlags.seen || message.imapUIFlags?.seen ?? false
        dateText =  (message.sent ?? Date()).smartString()
        profilePictureComposer = PepProfilePictureComposer()
        displayedUsername = MessageViewModel.getDisplayedUsername(for: message)
        setBodyPeek(for: message)
    }

    public func unsubscribeForUpdates() {
        queueForHeavyStuff.cancelAllOperations()
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

    public class func getSummary(fromMessage msg: Message) -> String {
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
            body = truncatedHtml.extractTextFromHTML(respectNewLines: false)

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

    public func getProfilePicture(completion: @escaping (UIImage?) -> ()) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                // Do nothing ...
                return
            }
            let operation = me.getProfilePictureOperation(completion: completion)
            me.queueForHeavyStuff.addOperation(operation)
        }
    }

    public func getSecurityBadge(completion: @escaping (UIImage?)->Void) {
        message.securityBadgeForContactPicture { (image) in
            DispatchQueue.main.async {
                completion(image)
            }
        }
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

// MARK: Private
// MARK: Operations

extension MessageViewModel {

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

    private func getProfilePictureOperation(completion: @escaping (UIImage?) -> ())
    -> SelfReferencingOperation {
        let identitykey = IdentityImageTool.IdentityKey(identity: displayedImageIdentity)
        let profilePictureOperation = SelfReferencingOperation { [weak self] operation in
            guard let me = self else {
                return
            }
            guard
                let operation = operation,
                !operation.isCancelled else {
                return
            }
            let profileImage = me.profilePictureComposer.profilePicture(for: identitykey)
            DispatchQueue.main.async {
                completion(profileImage)
            }
        }
        return profilePictureOperation
    }
}

// MARK: Helpers

extension MessageViewModel {

    private func setBodyPeek(for message: Message) {
        if let bodyPeek = internalBoddyPeek {
            self.bodyPeek = bodyPeek
        } else {
            let operation = getBodyPeekOperation(for: message) { [weak self] bodyPeek in
                // It's valid to loose self here. The view can dissappear @ any time.
                self?.bodyPeek = bodyPeek
            }
            queueForHeavyStuff.addOperation(operation)
        }
    }

    private static func getDisplayedUsername(for message: Message) -> String {
        if (message.parent.folderType == .sent || message.parent.folderType == .drafts) {
            return message.allRecipients.map { $0.userNameOrAddress }.joined(separator: ", ")
        }
        return message.from?.userNameOrAddress ?? ""
    }

    private func informIfBodyPeekCompleted() {
        guard let bodyPeek = bodyPeek else {
            return
        }
        bodyPeekCompletion?(bodyPeek)
        bodyPeekCompletion = nil
    }

    private class func identityForImage(from message: Message) -> Identity {
        switch message.parent.folderType {
        case .all, .archive, .spam, .trash, .flagged, .inbox, .normal, .pEpSync:
            return (message.from ?? Identity(address: "unknown@unknown.com"))
        case .drafts, .sent, .outbox:
            return message.to.first ?? Identity(address: "unknown@unknown.com")
        }
    }
}
