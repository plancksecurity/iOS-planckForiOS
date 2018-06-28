//
//  ThreadedFolderWithTop.swift
//  pEp
//
//  Created by Dirk Zimmermann on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Like `ThreadedFolder`, but interprets the top message as being part of the thread.
 */
class ThreadedFolderWithTop: ThreadedMessageFolderProtocol {
    let underlyingThreadedFolder: ThreadedMessageFolderProtocol

    init(folder: Folder) {
        underlyingThreadedFolder = ThreadedFolder(folder: folder)
    }

    func allMessages() -> [Message] {
        return underlyingThreadedFolder.allMessages()
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return underlyingThreadedFolder.numberOfMessagesInThread(message: message) + 1
    }

    func messagesInThread(message: Message) -> [Message] {
        var messages = underlyingThreadedFolder.messagesInThread(message: message)
        messages.append(message)
        return messages
    }

    func deleteSingle(message: Message) {
        underlyingThreadedFolder.deleteSingle(message: message)
    }

    func deleteThread(message: Message) {
        underlyingThreadedFolder.deleteThread(message: message)
    }

    func referencedTopMessages(message: Message) -> [Message] {
        return underlyingThreadedFolder.referencedTopMessages(message: message)
    }
}
