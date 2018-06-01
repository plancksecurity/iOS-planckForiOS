//
//  DisplayedMessage.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 01/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
protocol DisplayedMessage: class {

    /**
     The email detail should mark the message as flagged
     */
    func markAsFlagged()

    /**
     The email detail should mark the message as unflagged
     */
    func markAsUnflagged()
}
