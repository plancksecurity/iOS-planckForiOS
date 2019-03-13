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
        return allCdMessages(ignoringPepRating: showsMessagesNeverSeenByEngine)
            .compactMap {
                return $0.message()
        }
    }
}
