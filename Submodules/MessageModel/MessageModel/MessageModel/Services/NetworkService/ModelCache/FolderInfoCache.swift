//
//  FolderInfoCache.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 Caches some information of a CdFolder in order to enable operations
 access to data in a thread-safe way, and also without having to operate
 in a context.
 */
public struct FolderInfoCache: Hashable {
    public let objectID: NSManagedObjectID
    public let name: String
    public let folderType: FolderType
    public let shouldNotAppendMessages: Bool

    init(cdFolder: CdFolder) {
        self.objectID = cdFolder.objectID
        self.name = cdFolder.nameOrCrash
        self.folderType = cdFolder.folderType
        self.shouldNotAppendMessages = cdFolder.shouldNotAppendMessages
    }

    public static func ==(l: FolderInfoCache, r: FolderInfoCache) -> Bool {
        return l.objectID == r.objectID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
