//
//  ThreadedFolderStub.swift
//  pEp
//
//  Created by Borja González de Pablo on 11/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class ThreadedFolderStub: ThreadedMessageFolderProtocol {
    var isThreaded = true

    func referencedTopMessages(message: Message) -> [Message] {
        return [Message]()
    }

    func isTop(newMessage: Message) -> Bool {
        return false
    }

    let underlyingFolder: Folder

    func allMessages() -> [Message] {
        var messages: [Message] = [Message]()
        for i in 0...3 {
            let message = Message.fakeMessage(uuid: MessageID.generate(), uid: UInt(i), folder: underlyingFolder)
            messages.append(message)
        }
        return messages
    }

    init(folder: Folder) {
        underlyingFolder = folder
    }

    func numberOfMessagesInThread(message: Message) -> Int {
        return 4
    }

    func messagesInThread(message: Message) -> [Message] {
        return allMessages()
    }

    func deleteSingle(message: Message) {
    }

    func deleteThread(message: Message) {
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
