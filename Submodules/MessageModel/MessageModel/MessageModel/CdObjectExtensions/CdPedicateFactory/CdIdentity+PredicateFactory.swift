//
//  CdIdentity+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 31.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdIdentity {

    struct PredicateFactory {

        /// Predicate to fetch CdIdentities that represents the user
        ///
        /// - Returns: predicate for own identities
        static func isMySelf() -> NSPredicate {
            return NSPredicate(format: "%K = %@", CdIdentity.AttributeName.userID, CdIdentity.pEpOwnUserID)
        }

        /// Predicate to fetch CdIdentities that represents the user
        ///
        /// - Returns: predicate for not own identities
        static public func isNotMySelf() -> NSPredicate {
            return NSPredicate(format: "%K != %@", CdIdentity.AttributeName.userID, CdIdentity.pEpOwnUserID)
        }

        /// - Returns: predicate for identities that that have no addressBookID
        static func contactsIdentifierUnknown() -> NSPredicate {
            return NSPredicate(format: "%K = nil", CdIdentity.AttributeName.addressBookID)
        }


        /// Predicate to search over identities
        ///
        /// - Parameter value: string to search
        /// - Returns: Predicate for identities that contains the given search term in the address or username
        static func addressOrUserNameContains(searchTerm: String) -> NSPredicate {
            var orPredicates = [NSPredicate]()
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdIdentity.AttributeName.address, searchTerm))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdIdentity.AttributeName.userName, searchTerm))
            return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
        }
        
        /// Predicate to search for suggested identities
        /// - Parameter searchTerm: String to make the search
        /// - Returns: Predicate for identities that fit in the suggestion with the expected search term
        static func recipientSuggestions(for searchTerm: String) -> NSPredicate {
            var orPredicates = [NSPredicate]()
            orPredicates.append(NSPredicate(format: "%K BEGINSWITH[C] %@",
                                            CdIdentity.AttributeName.userName, searchTerm))
            orPredicates.append(NSPredicate(format: "%K BEGINSWITH[C] %@",
                                            CdIdentity.AttributeName.address, searchTerm))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdIdentity.AttributeName.userName, " " + searchTerm))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdIdentity.AttributeName.address, "." + searchTerm))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdIdentity.AttributeName.address, "-" + searchTerm))
            return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
        }

        /// predicate to search all identities with the same userID
        ///
        /// - Parameter value: usearID to search
        /// - Returns: Predicate for identities with the same userID in the given parameter
        static func sameUserID(value: String) -> NSPredicate {
            return NSPredicate(format: "%K == %@", CdIdentity.AttributeName.userID, value)
        }
    }

}
