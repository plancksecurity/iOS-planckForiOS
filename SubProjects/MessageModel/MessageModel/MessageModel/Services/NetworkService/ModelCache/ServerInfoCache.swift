//
//  ServerInfoCache.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 Caches some information of a CdServer in order to enable operations
 access to data in a thread-safe way, and also without having to operate
 in a context.
 */
struct ServerInfoCache: Hashable {
    let objectID: NSManagedObjectID
    let hash: Int

    init(cdServer: CdServer) {
        self.objectID = cdServer.objectID
        self.hash = cdServer.hash
    }

    static func ==(l: ServerInfoCache, r: ServerInfoCache) -> Bool {
        return l.objectID == r.objectID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
