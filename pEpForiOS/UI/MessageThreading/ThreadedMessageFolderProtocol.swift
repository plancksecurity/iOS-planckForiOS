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
     Assuming the given message is part of a thread, returns all the count of
     all (known) messages in the thread.
     - Note:
       * See `messagesInThread()`
       * A single (unthreaded) message will have a count of 0. As soon as another message
     belongs to the same thread, the count will be 2. So this will never yield 1.
     */
    func numberOfMessagesInThread(message: Message) -> Int

    /**
     - Returns: _All_ messages belonging to the same thread.
     - Note:
       * Includes the given `message` in the list.
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

    /**
     Generalized version of `referencedTopMessages`, in case you already know the
     top messages.
     - Returns: An array of indices into `messageIdentifiers` where the message-id
     is contained in `belongingToThread`.
     */
    func referenced<T>(
        messageIdentifiers: [T],
        belongingToThread: Set<MessageID>) -> [Int] where T: MessageIdentitfying

    /**
     Generalized version of `referencedTopMessages`, in case you already know the
     top messages.
     - Returns: An array of indices into `messageIdentifiers` where the message-id
     was part of the thread that `message` is a part of.
     */
    func referenced<T>(
        messageIdentifiers: [T],
        message: Message) -> [Int] where T: MessageIdentitfying
}
