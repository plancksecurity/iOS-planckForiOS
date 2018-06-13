//
//  FolderThreading.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class FolderThreading {
    static func factory() -> ThreadedMessageFolderFactoryProtocol {
        return ThreadAwareFolderFactory()
    }

    /**
     Shortcut that lets you implicitly use the factory received by calling
     `factory()`.
     */
    static func makeThreadAware(folder: Folder) -> ThreadedMessageFolderProtocol {
        return factory().makeThreadAware(folder: folder)
    }
}
