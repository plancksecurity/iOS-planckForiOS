//
//  ThreadedFolderStub.swift
//  pEp
//
//  Created by Borja González de Pablo on 11/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class ThreadedFolderStub: ThreadedMessageFolderProtocol{

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


}
