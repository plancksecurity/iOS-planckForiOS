//
//  CdFolder+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 29.08.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdFolder {
    struct PredicateFactory {

        static func inAccount(cdAccount: CdAccount) -> NSPredicate {
            return NSPredicate(format: "%K = %@", CdFolder.RelationshipName.account, cdAccount)
        }

        /**
         - Returns: A predicate for all the messages in that folder.
         */
        static func containedMessages(cdFolder: CdFolder) -> NSPredicate {
            return NSPredicate(format: "%K = %@", CdFolder.RelationshipName.parent, cdFolder)
        }

        static func predicateForFolder(ofType type: FolderType) -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                               CdFolder.AttributeName.folderTypeRawValue,
                               type.rawValue)
        }

        /// Predicate for fetching the pEp sync folder ("sync folder mode").
        /// - Parameter cdAccount: The account to take the folder separator from,
        /// and where to look for the folder.
        static func pEpSyncFolder(cdAccount: CdAccount) -> NSPredicate {
            return NSPredicate(format: "%K = %@ AND %K = %d",
                               CdFolder.RelationshipName.account,
                               cdAccount,
                               CdFolder.AttributeName.folderTypeRawValue,
                               FolderType.pEpSync.rawValue)
        }

        static func folders(for cdAccount: CdAccount, lastLookedAfter date: Date) -> NSPredicate {
            return NSPredicate(format: "%K = %@ AND %K > %@ AND %K IN %@",
                               CdFolder.RelationshipName.account, cdAccount,
                               CdFolder.AttributeName.lastLookedAt, date as CVarArg,
                               CdFolder.AttributeName.folderTypeRawValue, FolderType.typesSyncedWithImapServerRawValues)
        }
    }
}

/// IMAP specific predicates (MessageModel should not be aware of)
extension CdFolder.PredicateFactory {

    static func isSyncedWithServer() -> NSPredicate {
        return NSPredicate(format: "%K IN %@",
                           CdFolder.AttributeName.folderTypeRawValue,
                           FolderType.typesSyncedWithImapServerRawValues)
    }
}
