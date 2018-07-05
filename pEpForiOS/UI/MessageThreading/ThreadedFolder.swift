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
        return message.referencingMessages()
    }

    func deleteSingle(message: Message) {
        message.imapDelete()
    }

    func deleteThread(message: Message) {
        let children = message.referencingMessages()
        for msgChild in children {
            msgChild.imapDelete()
        }
        message.imapDelete()
    }

    func referencedTopMessages(message: Message) -> [Message] {
        let topMessages = underlyingFolder.allMessagesNonThreaded()
        var result = [Message]()

        MessageModel.performAndWait {
            let referenceSet = Set(message.referencedMessages().map {
                return $0.messageID
            })

            // test for direct references

            for aTopMsg in topMessages {
                if referenceSet.contains(aTopMsg.messageID) {
                    result.append(aTopMsg)
                }
            }

            if !result.isEmpty {
                return
            }

            // if no direct references could be found, check for indirects

            for aTopMsg in topMessages {
                let topReferenceSet = Set(aTopMsg.referencedMessages().map {
                    return $0.messageID
                })
                if !topReferenceSet.intersection(referenceSet).isEmpty {
                    result.append(aTopMsg)
                }
            }
        }

        return result
    }

    // MARK: - Private

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
     Which of the given `referenceSet` is referenced by `message`?
     */
    private func referenced(message: Message, referenceSet:Set<MessageID>) -> Set<MessageID> {
        let refs = Set(message.references)
        return refs.intersection(referenceSet)
    }

    /**
     Does `message` reference any message-id from `referenceSet`?
     */
    private func doesReference(message: Message, referenceSet:Set<MessageID>) -> Bool {
        if referenced(message: message, referenceSet: referenceSet).isEmpty {
            return false
        } else {
            return true
        }
    }
}
