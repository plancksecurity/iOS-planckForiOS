//
//  ThreadAwareFolderFactory.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ThreadUnAwareFolderFactory: ThreadAwareFolderFactoryProtocol {
    func makeThreadAware(folder: Folder) -> ThreadAwareFolderProtocol {
        return UnthreadedFolder(folder: folder)
    }
}
