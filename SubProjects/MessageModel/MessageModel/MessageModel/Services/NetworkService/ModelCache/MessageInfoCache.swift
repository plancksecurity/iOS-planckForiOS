//
//  MessageInfoCache.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 02.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 Caches some information of a CdMessage in order to enable operations
 access data in a thread-safe way, and also without having to operate
 in a context.
 */
struct MessageInfoCache: Hashable {
    let objectID: NSManagedObjectID

    /** The name of the containing folder. */
    let folderName: String

    let uid: Int32

    init(cdMessage: CdMessage) {
        self.objectID = cdMessage.objectID
        self.folderName = cdMessage.parentOrCrash.nameOrCrash
        self.uid = cdMessage.uid
    }

    static func ==(l: MessageInfoCache, r: MessageInfoCache) -> Bool {
        return l.objectID == r.objectID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
