//
//  UpdateThreadListDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Methods for helping the email list notify a thread display (list of emails)
 of new, deleted or updated emails in that thread.
 */
protocol UpdateThreadListDelegate: class {
    /**
     A child-message that belongs to a thread got deleted.
     */
    func deleted(message: Message)

    /**
     A child-message that belongs to a thread got updated.
     */
    func updated(message: Message)

    /**
     A new child message came in.
     */
    func added(message: Message)
}
