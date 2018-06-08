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
    func didMove(messages: [Message?]) {
        if let first = messages.first
        , let message = first {
            delegate?.emailDisplayDidDelete(message: message)
        }
    }
}
