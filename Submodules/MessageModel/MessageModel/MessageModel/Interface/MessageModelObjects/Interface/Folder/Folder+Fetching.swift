//
//  Folder+Fetching.swift
//  MessageModel
//
//  Created by Andreas Buff on 11.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension Folder {

    /// Whether or not messages with PEP-Rating_none should be displayed to the user.
    private var showsMessagesNeverSeenByEngine : Bool {
        // In certain folder types (e.g.local folders), we want to display messages even they have
        // never met the Engine (and thus can not have a pEp rating).
        return folderType.isLocalFolder
    }

    public func messageCount() -> Int {
        return  allMessages().count //allCdMessagesCount(ignoringPepRating: showsMessagesNeverSeenByEngine) //!!!: lets CD count please
    }

    //!!!: should become obsolete
    public func messageAt(index: Int) -> Message? {
        if let message = allMessages()[safe: index] {
            return message
        }
        return nil
    }

    /// Returns: All the messages contained in that folder that are valid to show the user (not deleted ++).
    public func allMessages() -> [Message] {
        return
            allCdMessages(ignoringPepRating: showsMessagesNeverSeenByEngine)
                .compactMap { MessageModelObjectUtils.getMessage(fromCdMessage: $0) }
    }
}
