//
//  Folder+Threading.swift
//  pEp
//
//  Created by Andreas Buff on 31.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Folder {

    /**
     - Returns: All the messages contained in that folder in a flat and linear way,
     that is no threading involved.
     */
    public func allMessagesNonThreaded() -> [Message] {
        if self is UnifiedInbox {
            let cdMessages = CdMessage.all() ?? []
            return cdMessages.compactMap { ($0 as! CdMessage).message() }
        } else {
            guard let cdFolder = self.cdFolder() else {
                UIUtils.showAlertWithOnlyPositiveButton(title: "No CdFolder", message: "No CdFolder exists for folder: \(self)", inViewController: UIApplication.topViewController()!)
                return []
            }

            let belongsToFolder = NSPredicate(format: "parent = %@", cdFolder)
            let cdMessages = CdMessage.all(predicate: belongsToFolder) ?? []
            return cdMessages.compactMap { ($0 as! CdMessage).message() }
        }
    }
}
