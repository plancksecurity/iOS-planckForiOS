//
//  EmailViewController+DisplayedMessage.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 31/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension EmailViewController: DisplayedMessage {

    func markAsFlagged() {
       changeFlagButtonTo(flagged: true)

    }

    func markAsUnflagged() {
        changeFlagButtonTo(flagged: false)
    }
}
