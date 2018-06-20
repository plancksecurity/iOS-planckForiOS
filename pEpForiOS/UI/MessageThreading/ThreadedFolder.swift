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
        return true
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
            let refs = Set<MessageID>(msg.references)
            let intersection = refs.intersection(originalMessageIdSet)
            if !intersection.isEmpty {
                print("*** child message \(msg.messageID) is child of: \(intersection)")
            } else {
                print("*** top message   \(msg)")
                topMessages.append(msg)
            }
        }

        return topMessages
    }

    private func gatherTopMessagesWithReferences() -> (topMessages: [Message],
        messageIdsReferenced: Set<MessageID>) {
            let originalMessages = underlyingFolder.allMessagesNonThreaded()

            var topMessages = [Message]()
            var messageIdsReferenced = Set<MessageID>()

            // gather references
            for aMsg in originalMessages {
                MessageModel.performAndWait {
                    aMsg.referencedMessages().forEach {
                        messageIdsReferenced.insert($0.messageID)
                        print("*** \(aMsg.messageID) -> \($0.messageID)")
                    }
                }
            }

            // gather top messages
            for aMsg in originalMessages {
                if !messageIdsReferenced.contains(aMsg.messageID) {
                    topMessages.append(aMsg)
                }
            }

            return (topMessages: topMessages, messageIdsReferenced: messageIdsReferenced)
    }
}
