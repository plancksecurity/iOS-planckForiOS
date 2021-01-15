//
//  Message+clone.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 13/08/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Message {
    public func cloneWithZeroUID(session: Session) -> Message {
        let clonedCdMessage = cdObject.cloneWithZeroUID(context: session.moc)
        return MessageModelObjectUtils.getMessage(fromCdMessage: clonedCdMessage)
    }
}
