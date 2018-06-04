//
//  ThreadAwareFolderProtocol.swift
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
protocol ThreadAwareFolderProtocol {
    /**
     Depending on whether the underlying implmentation is configured to
     show threads or not, this will return a list of all messages or just
     the top messages of the threads.
     */
    func allMessages(forFolder folder: Folder) -> [Message]

    /**
     Removes a single message, never a whole thread.
     */
    func imapDelete(message: Message)

    /**
     Assuming this message is the last one of its thread, remove it and all messages
     before it.
     */
    func deleteThread(message: Message)
}
