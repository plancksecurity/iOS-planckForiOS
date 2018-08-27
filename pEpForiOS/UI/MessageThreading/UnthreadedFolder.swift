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
    var isThreaded = false

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

    func referencedTopMessages(message: Message) -> [Message] {
        return [] // make it seem this is a top message
    }

    func referenced<T>(messageIdentifiers: [T],
                       belongingToThread: Set<MessageID>) -> [Int] where T: MessageIdentitfying {
        return []
    }

    func referenced<T>(
        messageIdentifiers: [T],
        message: Message) -> [Int] where T: MessageIdentitfying {
        return []
    }
}
