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
 Extensions for making a `Folder` thread aware.
 */
extension Folder {
    public func allMessagesNonThreaded() -> [Message] {
        return FolderThreading.makeThreadAware(folder: self).allMessages()
    }
}
