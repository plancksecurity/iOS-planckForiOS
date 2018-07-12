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

    /**
     - Returns: The top messages of a folder, that is all messages fulfilling the
     underlying folder's filter that are at the top of threads.
     - Note: For performance reasons, the basic check is if a message is a child of
     the previous one, so the first message (and in most cases newest) is always a top message.
     */
    func allMessages() -> [Message] {
        var topMessages = [Message]()

        var messageIdSet = Set<MessageID>()
        let originalMessages = underlyingFolder.allMessagesNonThreaded()

        MessageModel.performAndWait {
            for msg in originalMessages {
                let threadMessageIds = msg.threadMessageIdSet()
                if messageIdSet.intersection(threadMessageIds).isEmpty {
                    topMessages.append(msg)
                }
                messageIdSet.formUnion(threadMessageIds)
            }
        }

        return topMessages
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return messagesInThread(message: message).count
    }

    func messagesInThread(message: Message) -> [Message] {
        let thread = message.threadMessages()
        if thread.count == 1 {
            return []
        } else {
            return thread
        }
    }

    func deleteSingle(message: Message) {
        message.imapDelete()
    }

    func deleteThread(message: Message) {
        let children = messagesInThread(message: message)
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
}
