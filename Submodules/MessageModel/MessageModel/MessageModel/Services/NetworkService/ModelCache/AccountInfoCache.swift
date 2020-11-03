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
public struct AccountInfoCache: Hashable {
    public let objectID: NSManagedObjectID
    public let hash: Int
    public let address: String

    init(cdAccount: CdAccount) {
        self.objectID = cdAccount.objectID
        self.hash = cdAccount.hash
        self.address = cdAccount.identityOrCrash.addressOrCrash
    }

    public static func ==(l: AccountInfoCache, r: AccountInfoCache) -> Bool {
        return l.objectID == r.objectID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
