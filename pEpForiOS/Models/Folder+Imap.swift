//
//  Folder+Imap.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Logic based on data MessageModel should not know.
extension Folder {

    public func indexOf(message: Message) -> Int? {
        let i2 = indexOfBinary(message: message)
        return i2
    }

    /**
     - Returns: All the messages contained in that folder in a flat and linear way,
     that is no threading involved.
     */
    public func allMessagesNonThreaded() -> [Message] {
        return allCdMessagesNonThreaded().compactMap {
            return $0.message()
        }
    }

    public func messageAt(index: Int) -> Message? {
        if let cdMessage = allCdMessagesNonThreaded()[safe: index] {
            return cdMessage.message()
        }
        return nil
    }

    func indexOfBinary(message: Message) -> Int? {
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
        let msgs = allCdMessagesNonThreaded()
        return msgs.binarySearch(element: cdMsg, comparator: comparator)
    }
}
