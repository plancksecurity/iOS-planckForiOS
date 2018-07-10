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
    // MARK: - Public

    /**
     Makes `factory` the `ThreadedMessageFolderFactoryProtocol` to use.
     */
    static func override(factory: ThreadedMessageFolderFactoryProtocol) {
        theFactory = factory
    }

    static func factory() -> ThreadedMessageFolderFactoryProtocol {
        return theFactory ?? ThreadAwareFolderFactory()
    }

    /**
     Shortcut for `override` based on boolean "threading on or off".
     */
    static func switchThreading(onOrOff: Bool) {
        if onOrOff {
            override(factory: ThreadAwareFolderFactory())
        } else {
            override(factory: ThreadUnAwareFolderFactory())
        }
    }

    /**
     Shortcut that lets you implicitly use the factory received by calling
     `factory()`.
     */
    static func makeThreadAware(folder: Folder) -> ThreadedMessageFolderProtocol {
        return factory().makeThreadAware(folder: folder)
    }

    // MARK: - Private

    private static var theFactory: ThreadedMessageFolderFactoryProtocol?
}
