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
        return computeTopMessages(messages: underlyingFolder.allMessagesNonThreaded())
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

    func isTop(newMessage: Message) -> Bool {
        let allCurrentMessageIds = underlyingFolder.allMessagesNonThreaded().map {
            return $0.messageID
        }
        let allCurrentMessageIdsSet = Set(allCurrentMessageIds)
        return !doesReference(message: newMessage, referenceSet: allCurrentMessageIdsSet)
    }

    // MARK - Private

    /**
     Determine which messages in the given list don't reference any other message in the list.
     */
    private func computeTopMessages(messages: [Message]) -> [Message] {
        var topMessages = [Message]()

        let originalMessageIds = messages.map {
            return $0.messageID
        }
        let originalMessageIdSet = Set<MessageID>(originalMessageIds)

        for msg in messages {
            if !doesReference(message: msg, referenceSet: originalMessageIdSet) {
                topMessages.append(msg)
            }
        }

        return topMessages
    }

    /**
     Does `message` reference any message-id from `referenceSet`?
     */
    private func doesReference(message: Message, referenceSet:Set<MessageID>) -> Bool {
        let refs = Set(message.references)
        let intersection = refs.intersection(referenceSet)
        if intersection.isEmpty {
            return false
        } else {
            return true
        }
    }
}
