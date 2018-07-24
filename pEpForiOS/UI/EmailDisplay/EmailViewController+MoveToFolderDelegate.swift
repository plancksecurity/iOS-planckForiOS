//
//  EmailViewController+MoveToFolderDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 04/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension EmailViewController: MoveToFolderDelegate {
    func didmove(messages: [Message]) {
        self.didMove()
    }

    func didMove() {
        if let msg = self.message {
            delegate?.emailDisplayDidDelete(message: msg)
        }
    }
}
