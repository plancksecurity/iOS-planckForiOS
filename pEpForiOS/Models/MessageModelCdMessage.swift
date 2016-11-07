//
//  MessageModelCdMessage.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 03/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension MessageModel.CdMessage {
    
    static func basicMessagePredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate.init(format: "pepColorRating != nil")
        let predicateBody = NSPredicate.init(format: "bodyFetched = true")
        let predicateNotDeleted = NSPredicate.init(format: "flagDeleted = false")
        let predicates: [NSPredicate] = [predicateBody, predicateDecrypted,
                                         predicateNotDeleted]
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        return predicate
    }
}
