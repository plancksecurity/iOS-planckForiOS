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
    func didMove(message: Message?) {
        if let message = message {
            delegate?.emailDisplayDidDelete(message: message)
        }
    }
}
