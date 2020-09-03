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

        static func isInUnified() -> NSPredicate {
            return NSPredicate(format: "%K = true",  CdAccount.AttributeName.includeFoldersInUnifiedFolders)
        }
    }
}
