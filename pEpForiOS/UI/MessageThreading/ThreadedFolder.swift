//
//  ThreadedFolder.swift
//  pEp
//
//  Created by Dirk Zimmermann on 05.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ThreadedFolder: ThreadedMessageFolderProtocol {
    let underlyingFolder: Folder

    init(folder: Folder) {
        underlyingFolder = folder
    }

    func allMessages() -> [Message] {
        let originalMessages = underlyingFolder.allMessagesNonThreaded()

        var topMessages = [Message]()
        var childMessagesAlreadyReferenced = Set<MessageID>()

        for aMsg in originalMessages {
            if !childMessagesAlreadyReferenced.contains(aMsg.messageID) {
                // this is a top message
                topMessages.append(aMsg)

                // note all children, in order to prevent to interpret them as
                // top messages when they are encountered
                for ref in aMsg.references {
                    childMessagesAlreadyReferenced.insert(ref)
                }
            }
        }
        return topMessages
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return message.referencedMessages().count
    }

    func messagesInThread(message: Message) -> [Message] {
        return message.referencedMessages()
    }

    func deleteSingle(message: Message) {
        message.imapDelete()
    }

    func deleteThread(message: Message) {
        deleteSingle(message: message)
    }
}
