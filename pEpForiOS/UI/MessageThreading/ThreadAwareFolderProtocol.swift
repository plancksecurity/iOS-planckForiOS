//
//  ThreadAwareFolderProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 05.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public protocol ThreadAwareFolderProtocol {
    /**
     - Returns: The list of messages contained in this folders. Depending on the setup,
     this could be the tips of the threads or all messages in a flat way.
     */
    func allMessages() -> [Message]
}
