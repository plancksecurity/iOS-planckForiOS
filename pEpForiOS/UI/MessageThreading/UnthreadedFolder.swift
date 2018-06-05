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
 Implementation of `ThreadAwareFolderProtocol` that ignores any threading.
 Can be used in case the user has disabled threading in the settings.
 */
class UnthreadedFolder: ThreadAwareFolderProtocol {
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
}
