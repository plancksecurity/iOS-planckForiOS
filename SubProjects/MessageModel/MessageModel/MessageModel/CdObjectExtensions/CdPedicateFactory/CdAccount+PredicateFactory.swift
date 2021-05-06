//
//  CdAccount+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 06/05/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdAccount {
    struct PredicateFactory {
        static func belongingToIdentity(identity: CdIdentity) -> NSPredicate {
            return NSPredicate(format: "%K = %@",
                               CdAccount.RelationshipName.identity,
                               identity)
        }
        /// Get CdAccount by address
        static func by(address: String) -> NSPredicate {
            return NSPredicate(format: "identity.address like[c] %@", address)
        }

        /// - Returns: The predicate to filter accounts that should be included in 'Unified Folders'
        static func isInUnified() -> NSPredicate {
            return NSPredicate(format: "%K = true",  CdAccount.AttributeName.includeFoldersInUnifiedFolders)
        }

        /// - Returns: The predicate to filter active accounts
        static func isActive() -> NSPredicate {
            return NSPredicate(format: "%K = true",  CdAccount.AttributeName.isActive)
        }

        /// - Returns: The predicate to filter active accounts that should be included in 'Unified Folders'
        static func isInUnifiedAndActive() -> NSPredicate {
            var predicates = [NSPredicate]()
            predicates.append(isActive())
            predicates.append(isInUnified())
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }
}
