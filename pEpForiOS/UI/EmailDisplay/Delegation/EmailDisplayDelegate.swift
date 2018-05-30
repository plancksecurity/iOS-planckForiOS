//
//  EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


protocol EmailDisplayDelegate: class {
    func emailDisplayDidFlagMessage(message:Message)
    func emailDisplayDidUnflagMessage(message:Message)
    func emailDisplay(didDeleteMessage message:Message)
}
