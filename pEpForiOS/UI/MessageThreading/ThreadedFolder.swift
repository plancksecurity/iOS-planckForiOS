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
        var topMessages = [Message]()

        var messageIdSet = Set<MessageID>()
        let originalMessages = underlyingFolder.allMessagesNonThreaded()

        MessageModel.performAndWait {
            for msg in originalMessages {
                let threadMessageSet = Set(msg.threadMessages().map {
                    return $0.messageID
                })
                if messageIdSet.intersection(threadMessageSet).isEmpty {
                    topMessages.append(msg)
                }
                messageIdSet.formUnion(threadMessageSet)
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
