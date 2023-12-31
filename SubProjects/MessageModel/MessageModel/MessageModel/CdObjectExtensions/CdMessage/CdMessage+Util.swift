//
//  CdMessage+Util.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 06.07.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import Foundation

import PlanckToolbox

/**
 Utility methods.
 */
extension CdMessage {
    /**
     For use by `sorted`, `sort`, sorts a sequence so that earlier messages appear first.
     */
    static func areInIncreasingOrder(_ cdMsg1: CdMessage, cdMsg2: CdMessage) -> Bool {
        return cdMsg1.isEarlierTo(cdMessage2: cdMsg2)
    }

    // MARK: Private

    /**
     Is this `CdMessage` earlier than `cdMessage2` by date, uid or message-id?
     */
    private func isEarlierTo(cdMessage2: CdMessage) -> Bool {
        if let d1 = sent, let d2 = cdMessage2.sent {
            let ct = d1.compare(d2)
            return ct == .orderedAscending
        } else if let parent1 = parent, let parent2 = cdMessage2.parent, parent1 == parent2,
            uid != 0, cdMessage2.uid != 0 {
            return uid < cdMessage2.uid
        } else {
            // try to give it a stable ordering in any case
            if let mid1 = messageID, let mid2 = cdMessage2.messageID {
                return mid1 < mid2
            } else {
                return objectID.uriRepresentation().absoluteString
                    < cdMessage2.objectID.uriRepresentation().absoluteString
            }
        }
    }
}
