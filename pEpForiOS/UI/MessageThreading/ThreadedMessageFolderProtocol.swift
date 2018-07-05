//
//  ThreadedMessageFolderProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 An abstraction over UI interactions with `Folder`s and `Message`s that
 can deal with message threading transparently to the client.
 - Note: Objects implmenting this protocol can choose to ignore threading
 completely, which is transparent to the client.
 */
public protocol ThreadedMessageFolderProtocol {
    /**
     Depending on whether the underlying implmentation is configured to
     show threads or not, this will return a list of all messages or just
     the top messages of the threads.
     */
    func allMessages() -> [Message]

    /**
     Assuming the given message is the tip of the thread, returns all (known) messages
     in the thread that went before.
     - Note: Only downloaded, decrypted messages are considered.
     */
    func numberOfMessagesInThread(message: Message) -> Int

    /**
     - Returns: All messages belonging to the same thread, that went before.
     - Note:
       * Only downloaded, decrypted messages are considered
         (that is to say, they exist locally in the DB in unencrypted form).
       * They are ordered oldest to newest (if possible to determine).
     */
    func messagesInThread(message: Message) -> [Message]

    /**
     Removes a single message, never a whole thread.
     */
    func deleteSingle(message: Message)

    /**
     Assuming this message is the last one of its thread (the tip), remove it and all messages
     before it.
     */
    func deleteThread(message: Message)

    /**
     When a new message arrives, the client needs to find out if it belongs into to the
     message list (of thread tips), or if it's a message referenced by a top message
     (then it might have to go to the thread view).
     */
    func referencedTopMessages(message: Message) -> [Message]
}
