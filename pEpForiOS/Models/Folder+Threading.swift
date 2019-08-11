//
//  Folder+Threading.swift
//  pEp
//
//  Created by Andreas Buff on 31.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

//!!!: uses CD. move to MM. Or better re-move.
extension Folder {

    /// Returns: All the messages contained in that folder.
    public func allMessages() -> [Message] {
        return
            allCdMessages(ignoringPepRating: showsMessagesNeverSeenByEngine)
                .compactMap { $0.message() }
    }
}
