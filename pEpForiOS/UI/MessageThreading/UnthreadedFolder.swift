//
//  UnthreadedFolder.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Implementation of `ThreadedMessageFolderProtocol` that ignores any threading.
 Can be used in case the user has disabled threading in the settings.
 */
class UnthreadedFolder: ThreadedMessageFolderProtocol {
    let underlyingFolder: Folder

    init(folder: Folder) {
        underlyingFolder = folder
    }

    func allMessages() -> [Message] {
        return underlyingFolder.allMessagesNonThreaded()
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return 0
    }

    func messagesInThread(message: Message) -> [Message] {
        return []
    }

    func deleteSingle(message: Message) {
        message.imapDelete()
    }

    func deleteThread(message: Message) {
        deleteSingle(message: message)
    }

    func isTop(newMessage: Message) -> Bool {
        // all messages are in a flat list, so it's always a "top" message
        return true
    }
}
