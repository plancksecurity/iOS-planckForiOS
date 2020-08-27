//
//  CdFolder+SyncFolderMode.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.12.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/// Support for sync folder mode: https://dev.pep.foundation/Engine/SyncFolderMode
extension CdFolder {
    static let pEpSyncFolderName = "pEp"

    /// Tries to fetch the pEp sync folder for the given account.
    static func pEpSyncFolder(in moc: NSManagedObjectContext, cdAccount: CdAccount) -> CdFolder? {
        let p = CdFolder.PredicateFactory.pEpSyncFolder(cdAccount: cdAccount)
        return CdFolder.first(predicate: p, in: moc)
    }
}
