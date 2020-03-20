//
//  CdExtraKeys+Convenience.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension CdExtraKey {

    // - returns all CdExtraKeys in the database
    static func allExtraKeys(in context: NSManagedObjectContext) -> [CdExtraKey] {
        return  CdExtraKey.all(in: context) ?? []
    }

    // - returns the fingerprints of all CdExtraKeys in the database
    static func fprsOfAllExtraKeys(in context: NSManagedObjectContext) -> [String]? {
        let extraKeys = allExtraKeys(in: context)
        return extraKeys.compactMap { $0.fingerprint }
    }
}
