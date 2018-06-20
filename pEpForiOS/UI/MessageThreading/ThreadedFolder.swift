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
        let (topMessages, _) = gatherTopMessagesWithReferences()
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

    func isTop(newMessage: Message) -> Bool {
        var (topMessages, messageIdsReferenced) = gatherTopMessagesWithReferences()
        for msg in topMessages {
            if msg == newMessage {
                // The new message should be included in top message.
                // Make sure its references are not taken into account.
                for ref in msg.references {
                    messageIdsReferenced.remove(ref)
                }
            } else {
                messageIdsReferenced.insert(msg.messageID)
            }
        }

        for ref in newMessage.references {
            if messageIdsReferenced.contains(ref) {
                return false
            }
        }

        return true
    }

    // MARK - Private

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
