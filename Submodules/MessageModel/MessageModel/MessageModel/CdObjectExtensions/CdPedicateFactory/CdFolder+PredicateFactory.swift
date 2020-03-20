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
    }
}

/// IMAP specific predicates (MessageModel should not be aware of)
extension CdFolder.PredicateFactory {

    static  func isSyncedWithServer() -> NSPredicate {
        return NSPredicate(format: "%K IN %@",
                           CdFolder.AttributeName.folderTypeRawValue,
                           FolderType.typesSyncedWithImapServerRawValues)
    }
}
