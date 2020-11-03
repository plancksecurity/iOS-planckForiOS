//
//  Message+Factory.swift
//  MessageModel
//
//  Created by Andreas Buff on 31.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

// MARK: - Message+Factory

extension Message {

    /// Inserts a new CdMessage and preconfigures it to be ready to use as outgoing message.
    /// - Parameter session: Session to create message on.
    static public func newOutgoingMessage(session: Session = Session.main) -> Message {
        let cdCreatee = CdMessage.newOutgoingMessage(context: session.moc)
        return MessageModelObjectUtils.getMessage(fromCdMessage: cdCreatee,
                                                  context: session.moc)
    }
}
