//
//  PreviewMessage+ThreadAware.swift
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
extension PreviewMessage: ThreadAwareMessageProtocol {
    func numberOfMessagesInThread() -> Int {
        return message()?.numberOfMessagesInThread() ?? 0
    }

    func messagesInThread() -> [Message] {
        if let theMessage = message() {
            return FolderThreading.makeThreadAware(folder: theMessage.parent).messagesInThread(
                message: theMessage)
        } else {
            return []
        }
    }
}
