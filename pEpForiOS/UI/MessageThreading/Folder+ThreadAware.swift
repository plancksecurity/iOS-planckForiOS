//
//  Folder+Threaded.swift
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
extension Folder: ThreadAwareFolderProtocol {
    public func threadAware() -> ThreadedMessageFolderProtocol {
        return FolderThreading.makeThreadAware(folder: self)
    }

    public func allMessages() -> [Message] {
        return threadAware().allMessages()
    }
}
