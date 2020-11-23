//
//  CdHeaderField+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 06/05/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdHeaderField {
    struct PredicateFactory {
        static func itemsWithoutAnyRelationshipMessage() -> NSPredicate {
            return NSPredicate(format: "%K = nil",
                               CdHeaderField.RelationshipName.message)
        }
    }
}
