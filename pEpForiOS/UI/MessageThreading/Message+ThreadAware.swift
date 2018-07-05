//
//  Message+Threaded.swift
//  pEp
//
//  Created by Dirk Zimmermann on 05.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Some threading support.
 */
extension Message: ThreadAwareMessageProtocol {
    func threadAware() -> ThreadedMessageFolderProtocol {
        return FolderThreading.makeThreadAware(folder: parent)
    }

    func numberOfMessagesInThread() -> Int {
        return threadAware().numberOfMessagesInThread(
            message: self)
    }

    func messagesInThread() -> [Message] {
        return threadAware().messagesInThread(message: self)
    }
}
