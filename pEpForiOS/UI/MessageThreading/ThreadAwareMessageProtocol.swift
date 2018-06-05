//
//  ThreadAwareMessageProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 05.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol ThreadAwareMessageProtocol {
    /**
     - Returns: The count of `messagesInThread(message:)`
     */
    func numberOfMessagesInThread() -> Int

    /**
     If threading support is enabled, and the message is the tip of a thread,
     then this delivers the messages 'below' in that thread.
     */
    func messagesInThread() -> [Message]
}
