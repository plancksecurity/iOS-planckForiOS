//
//  ThreadedEmailViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 08/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class ThreadedEmailViewModel {
    let contactImageTool = IdentityImageTool()

    class Row {
        var senderContactImage: UIImage?
        var ratingImage: UIImage?
        var showAttchmentIcon: Bool = false
        let from: String
        let to: String
        let subject: String
        let bodyPeek: String
        var isFlagged: Bool = false
        var isSeen: Bool = false
        var dateText: String
        var opened: Bool = false
        let body: String

        init(withPreviewMessage pvmsg: FullyDisplayedMessage, senderContactImage: UIImage? = nil) {
            self.senderContactImage = senderContactImage
            showAttchmentIcon = pvmsg.hasAttachments
            from = pvmsg.from.userNameOrAddress
            to = pvmsg.to
            subject = pvmsg.subject
            bodyPeek = pvmsg.bodyPeek
            isFlagged = pvmsg.isFlagged
            isSeen = pvmsg.isSeen
            dateText = pvmsg.dateSent.smartString()
            body = pvmsg.body
        }
    }

    private let messages: [Message]
    private let folder: ThreadedFolderStub

    init(tip: Message, folder: Folder) {
      //  messages = tip.messagesInThread()
        messages = folder.allMessages()
        self.folder = ThreadedFolderStub(folder: folder)
    }

    func deleteMessage(at index: Int){
        folder.deleteSingle(message: messages[index])
    }

    func row(for index: Int) -> Row? {
        let previewMessage = FullyDisplayedMessage(withMessage: messages[index])
        if let cachedSenderImage = contactImageTool.cachedIdentityImage(forIdentity: previewMessage.from) {
            return Row(withPreviewMessage: previewMessage, senderContactImage: cachedSenderImage)
        } else {
            return Row(withPreviewMessage: previewMessage)
        }
    }

    func rowCount() -> Int {
        return messages.count
    }
}
