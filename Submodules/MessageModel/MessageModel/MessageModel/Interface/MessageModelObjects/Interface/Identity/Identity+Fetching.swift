//
//  Identity+Fetching.swift
//  MessageModel
//
//  Created by Xavier Algarra on 29/04/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Identity {
    /// Finds an Identity using the recipientSuggestions predicate
    /// - Parameters:
    ///   - searchTerm: value to search Identity for
    ///   - session: session to work on. Defaults to .main
    /// - Returns: suggested identities
    public static func recipientsSuggestions(for searchTerm: String, session: Session? = Session.main) -> [Identity] {
        let moc = session?.moc ?? Session.main.moc
        let predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: searchTerm)
        let sortUserName = NSSortDescriptor(key: CdIdentity.AttributeName.userName, ascending: true)
        let sortAddress = NSSortDescriptor(key: CdIdentity.AttributeName.address, ascending: true)
        
        guard
            let ids = CdIdentity.all(predicate: predicate, orderedBy: [sortUserName, sortAddress], in: moc) as? [CdIdentity]
        else {
            return []
        }
        return ids.map { MessageModelObjectUtils.getIdentity(fromCdIdentity: $0) }
    }
}
