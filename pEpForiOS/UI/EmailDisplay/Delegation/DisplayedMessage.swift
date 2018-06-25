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
 Indicates changes from the master list of emails to the detail view.
 */
protocol DisplayedMessage: class {
    /**
     Set by the detail view whenever it is to show a message, so the
     model always knows what's the currently displayed one.
     */
    var messageModel: Message? { get }

    /**
     Updates the detail message with the master one.
     */
    func update(forMessage message: Message)
}
