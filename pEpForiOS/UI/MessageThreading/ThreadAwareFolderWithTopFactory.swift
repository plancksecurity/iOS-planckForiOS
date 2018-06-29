//
//  ThreadAwareFolderWithTopFactory.swift
//  pEp
//
//  Created by Dirk Zimmermann on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ThreadAwareFolderWithTopFactory: ThreadedMessageFolderFactoryProtocol {
    func makeThreadAware(folder: Folder) -> ThreadedMessageFolderProtocol {
        return ThreadedFolderWithTop(folder: folder)
    }
}
