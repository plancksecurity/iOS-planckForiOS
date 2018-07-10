//
//  DisplayedMessage.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 01/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

/**
 Protocol between master and detail view controller for displaying messages.
 */
protocol DisplayedMessage: class {
    /**
     Supposed to be set by the detail view controller  whenever it is to show a message, so the
     model always knows what's the currently displayed one.
     */
    var messageModel: Message? { get }

    /**
     Supposed to be called when the master view controller detects a change in `messageModel`,
     so the detail view controller is informed about changes.
     */
    func update(forMessage message: Message)
}
