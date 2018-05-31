//
//  EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

/**
 The `EmailDisplayDelegate` protocol is adopted by an object that manages the email detail changes
 in its model
 */
protocol EmailDisplayDelegate: class {

    /**
     The email detail flagged the indicated message
     */
    func emailDisplayDidFlag(message: Message)

    /**
     The email detail unFlagged the indicated message
     */
    func emailDisplayDidUnflag(message: Message)

    /**
     The email detail deleted the indicated message
     */
    func emailDisplaydidDelete(message: Message)
}
