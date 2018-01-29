//
//  FolderSubscription.swift
//  pEp
//
//  Created by Andreas Buff on 29.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

struct FolderSubscription {

    /// Figures out whether or not we should subscribe to a folder.
    ///
    /// - Parameter folder: folder to investigate
    /// - Returns: true: if we should subscribe to the given folder. false otherwize.
   static func subscribe(to folder: Folder) -> Bool {
        // Gmail uses root folders in square brackets that must be ignored. "[Gmail]" for instance.
        // See IOS-902 for details
        if folder.name.hasPrefix("[") && folder.name.hasSuffix("]") {
            return false
        }
        return true
    }
}
