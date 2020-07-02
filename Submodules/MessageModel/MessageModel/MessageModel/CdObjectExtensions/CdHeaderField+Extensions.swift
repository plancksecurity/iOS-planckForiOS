//
//  CdHeaderField+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension CdHeaderField {

    //???: looks fishy like a workaround. Tripple check and fix the actual issue instead of working around if so.
    static func deleteOrphans(context: NSManagedObjectContext) {
        let p = CdHeaderField.PredicateFactory.itemsWithoutAnyRelationshipMessage()
        if let orphans = CdHeaderField.all(predicate: p, in: context) as? [CdHeaderField] {
            for o in orphans {
                context.delete(o)
            }
        }
    }
}
