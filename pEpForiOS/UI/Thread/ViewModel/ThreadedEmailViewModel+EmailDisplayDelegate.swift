//
//  ThreadedEmailViewModel+EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 04/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension ThreadedEmailViewModel: EmailDisplayDelegate {

    func emailDisplayDidFlag(message: Message) {
        updateInternal(message: message)
        emailDisplayDelegate?.emailDisplayDidFlag(message: message)

    }

    func emailDisplayDidUnflag(message: Message) {
        updateInternal(message: message)
        emailDisplayDelegate?.emailDisplayDidUnflag(message: message)

    }

    func emailDisplayDidDelete(message: Message) {
        deleteInternal(message: message)
        emailDisplayDelegate?.emailDisplayDidDelete(message: message)
    }

    func emailDisplayDidChangeMarkSeen(message: Message) {
        //FIXME: when implementing message threading
        fatalError("Unimplemented stub")
    }
    
    func emailDisplayDidChangeRating(message: Message) {
        updateInternal(message: message)
        emailDisplayDelegate?.emailDisplayDidChangeRating(message: message)
    }
}
