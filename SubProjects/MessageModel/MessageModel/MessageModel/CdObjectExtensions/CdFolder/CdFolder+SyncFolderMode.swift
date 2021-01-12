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

    /// Predicate for fetching the pEp sync folder ("sync folder mode").
    /// - Parameter cdAccount: The account to take the folder separator from,
    /// and where to look for the folder.
    static func pEpSyncFolderPredicate(cdAccount: CdAccount) -> NSPredicate {
        return NSPredicate(format: "%K = %@ AND %K = %d",
                           CdFolder.RelationshipName.account,
                           cdAccount,
                           CdFolder.AttributeName.folderTypeRawValue,
                           FolderType.pEpSync.rawValue)
    }

    /// Tries to fetch the pEp sync folder for the given account.
    static func pEpSyncFolder(in moc: NSManagedObjectContext, cdAccount: CdAccount) -> CdFolder? {
        let p = pEpSyncFolderPredicate(cdAccount: cdAccount)
        return CdFolder.first(predicate: p, in: moc)
    }
}
