//
//  EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol EmailDisplayDelegate: class {
    func emailDisplayDidFlagMessage(emailViewController: EmailViewController)
    func emailDisplayDidUnflagMessage(emailViewController: EmailViewController)
    func emailDisplayDidDeleteMessage(emailViewController: EmailViewController)
}
