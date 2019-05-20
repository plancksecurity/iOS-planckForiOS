//
//  Folder+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 31.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

//!!!: must be moved to MM
extension Folder {

    /// Whether or not messages with PEP-Rating_none should be displayed to the user.
    var showsMessagesNeverSeenByEngine : Bool {
        // In certain folder types (e.g.local folders), we want to display messages even they have
        // never met the Engine (and thus can not have a pEp rating).
        return folderType.isLocalFolder
    }

    public func messageCount() -> Int {
        return  allMessagesNonThreaded().count //allCdMessagesCount(ignoringPepRating: showsMessagesNeverSeenByEngine) //!!!: let CD count please
    }

    //!!!: should become obsolete
    public func messageAt(index: Int) -> Message? {
        if let message = allMessagesNonThreaded()[safe: index] {
            return message
        }
        return nil
    }
}
