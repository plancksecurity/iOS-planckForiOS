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
     A thread-tip message, or in an unthreaded setting, any message
     got deleted that currently has details displayed.
     In any case, this message was
     * part of the master view of messages
     * currently displayed in the detail view
     */
    func deleted(topMessage: Message)

    /**
     A child-message that belongs to a thread got updated.
     */
    func updated(message: Message)

    /**
     A new child message came in.
     */
    func added(message: Message)
}
