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
        var messageIdsAlreadyReferenced = Set<MessageID>()

        for aMsg in originalMessages {
            if !messageIdsAlreadyReferenced.contains(aMsg.messageID) {
                // this is a top message
                topMessages.append(aMsg)

                MessageModel.performAndWait {
                    aMsg.referencedMessages().forEach {
                        messageIdsAlreadyReferenced.insert($0.messageID)
                    }
                }
            }
        }
        return topMessages
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return messagesInThread(message: message).count
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
