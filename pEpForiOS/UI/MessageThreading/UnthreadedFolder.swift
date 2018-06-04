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
    func allMessages(forFolder folder: Folder) -> [Message] {
        return folder.allMessages()
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return 0
    }

    func childMessagesInThread(message: Message) -> [Message] {
        return []
    }

    func deleteSingle(message: Message) {
        message.imapDelete()
    }

    func deleteThread(message: Message) {
        deleteSingle(message: message)
    }
}
