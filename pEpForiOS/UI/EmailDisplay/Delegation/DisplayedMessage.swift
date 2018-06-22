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
     Represented message or top message of the thread.
 */
    var messageModel: Message? {get}

    /**
     Updates the detail message with the master one. 
     */
    func update(forMessage message: Message)
}
