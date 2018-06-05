//
//  Message+Threaded.swift
//  pEp
//
//  Created by Dirk Zimmermann on 05.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension Message {
    func numberOfMessagesInThread(message: Message) -> Int {
        return FolderThreading.makeThreadAware(folder: parent).numberOfMessagesInThread(
            message: self)
    }

    func messagesInThread(message: Message) -> [Message] {
        return FolderThreading.makeThreadAware(folder: parent).messagesInThread(message: self)
    }
}
