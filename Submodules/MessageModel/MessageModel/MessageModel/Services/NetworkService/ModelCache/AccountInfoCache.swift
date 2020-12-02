//
//  AccountInfoCache.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 Caches some information of a CdAccount in order to enable operations
 access to data in a thread-safe way, and also without having to operate
 in a context.
 */
struct AccountInfoCache: Hashable {
    let objectID: NSManagedObjectID
    let hash: Int
    let address: String

    init(cdAccount: CdAccount) {
        self.objectID = cdAccount.objectID
        self.hash = cdAccount.hash
        self.address = cdAccount.identityOrCrash.addressOrCrash
    }

    static func ==(l: AccountInfoCache, r: AccountInfoCache) -> Bool {
        return l.objectID == r.objectID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
