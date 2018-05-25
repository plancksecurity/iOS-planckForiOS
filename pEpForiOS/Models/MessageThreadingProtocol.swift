//
//  MessageThreadingProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 25.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 A message object can implement this in order to support a threaded view.
 */
public protocol MessageThreadingProtocol {
    /**
     The number of messages contained in the thread that this message is the top of,
     including the message itself.
     - See: `threadAncestors`
     */
    var threadCount: Int { get }

    /**
     All previous messages in the thread that this message is the top of.
     - Note: Only lists ancestor messages, that is messages that went _before_ this one.
     The following holds true: `threadAncestors().count + 1 == threadCount`.
     */
    func threadAncestors() -> [Message]
}
