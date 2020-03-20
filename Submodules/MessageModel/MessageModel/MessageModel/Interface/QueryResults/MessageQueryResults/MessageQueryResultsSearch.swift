//
//  MessageQueryResultsSearch.swift
//  MessageModel
//
//  Created by Xavier Algarra on 25/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

///Struct that provides a interface to select the search text.
public struct MessageQueryResultsSearch {


    /// Creates a MessageQueryResultsSearch
    ///that can be used to get the predicates for a messages search
    ///
    /// - Parameter searchTerms: Text to be searched inside the messages
    public init(searchTerm searchTerms: String) {
        self.searchTerm = searchTerms
    }

    private let searchTerm: String

    ///predicate related to the text searched is generated on demand.
    public var predicate: NSPredicate {
        get {
            return CdMessage.PredicateFactory.messageContains(value: searchTerm)
        }
    }
}

// Mark: - Hashable

extension MessageQueryResultsSearch: Hashable {
    public func hash(into hasher: inout Hasher) {
        // `predicate.hashValue` is returning an unexpected value, that's why we use description.
        hasher.combine(predicate.description)
    }
}

// Mark: - Equatable

extension MessageQueryResultsSearch : Equatable {
    public static func ==(lhs: MessageQueryResultsSearch, rhs: MessageQueryResultsSearch) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
