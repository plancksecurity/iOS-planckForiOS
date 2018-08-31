//
//  Folder+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 31.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Folder {

    /// Whether or not messages with PEP-Rating_none should be displayed to the user.
    var showsMessagesNeverSeenByEngine : Bool {
        // In certain folder types (e.g.local folders), we want to display messages even they have
        // never met the Engine (and thus can not have a pEp rating).
        return folderType.isLocalFolder
    }

    public func messageCount() -> Int {
        return allCdMessagesNonThreaded(ignoringPepRating: showsMessagesNeverSeenByEngine).count
    }

    public func indexOf(message: Message) -> Int? {
        let i2 = indexOfBinary(message: message)
        return i2
    }

    public func messageAt(index: Int) -> Message? {
        if let message = allMessagesNonThreaded()[safe: index] {
            return message
        }
        return nil
    }

    private func indexOfBinary(message: Message) -> Int? {
        func comparator(m1: CdMessage, m2: CdMessage) -> ComparisonResult {
            for desc in defaultSortDescriptors() {
                let c1 = desc.compare(m1, to: m2)
                if c1 != .orderedSame {
                    return c1
                }
            }
            return .orderedSame
        }
        guard let cdMsg = CdMessage.search(message: message) else {
            return nil
        }
        let msgs = allCdMessagesNonThreaded(ignoringPepRating: showsMessagesNeverSeenByEngine)
        return msgs.binarySearch(element: cdMsg, comparator: comparator)
    }
}
