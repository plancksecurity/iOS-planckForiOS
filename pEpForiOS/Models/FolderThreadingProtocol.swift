//
//  FolderThreadingProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 25.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public protocol FolderThreadingProtocol {
    /**
     Retrieves all messages in this folder.
     - Parameter isThreaded: When set to `true`, only the tips of threads will
     be returned.
     */
    func allMessages(isThreaded: Bool) -> [Message]
}
