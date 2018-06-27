//
//  ThreadedEmailViewModel+MoveToFolderDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 27/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension ThreadedEmailViewModel: MoveToFolderDelegate{
    func didMove() {
        emailDisplayDelegate.emailDisplayDidDelete(message: messages[0])
    }
}
