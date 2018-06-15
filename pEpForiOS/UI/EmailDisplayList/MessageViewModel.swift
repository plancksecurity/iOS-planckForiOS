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
    let to: String
    let subject: String
    let bodyPeek: String
    var isFlagged: Bool = false
    var isSeen: Bool = false
    var dateText: String
    var messageCount: Int
    var profilePictureComposer: ProfilePictureComposer
    private var message: Message

    init(with message: Message, senderContactImage: UIImage? = nil) {
        self.senderContactImage = senderContactImage
        showAttchmentIcon = message.attachments.count > 0
        from = (message.from ?? Identity(address: "unknown@unknown.com")).userNameOrAddress
        address =  MessageViewModel.address(at: message.parent, from: message)
        to = message.to.first?.userNameOrAddress ?? ""
        subject = message.shortMessage ?? ""
        isFlagged = message.imapFlags?.flagged ?? false
        isSeen = message.imapFlags?.seen ?? false
        dateText =  (message.sent ?? Date()).smartString()
        messageCount = message.numberOfMessagesInThread()
        profilePictureComposer = PepProfilePictureComposer()
        bodyPeek = MessageViewModel.displayBody(fromMessage: message)
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

    private class func displayBody(fromMessage msg: Message) -> String {
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
        profilePictureComposer.getProfilePicture(for: address, completion: completion)
    }

    func getSecurityBadge(completion: @escaping (UIImage?) ->()) {
        profilePictureComposer.getSecurityBadge(for: message, completion: completion)
    }


}
    
