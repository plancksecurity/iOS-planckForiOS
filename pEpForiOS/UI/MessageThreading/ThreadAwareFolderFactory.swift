//
//  ThreadAwareFolderFactory.swift
//  pEp
//
//  Created by Dirk Zimmermann on 06.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ThreadAwareFolderFactory: ThreadedMessageFolderFactoryProtocol {
    func makeThreadAware(folder: Folder) -> ThreadedMessageFolderProtocol {
        return ThreadedFolder(folder: folder)
    }
}
