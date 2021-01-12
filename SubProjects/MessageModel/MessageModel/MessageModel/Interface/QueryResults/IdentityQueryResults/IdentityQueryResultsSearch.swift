//
//  IdentityQueryResultsSearch.swift
//  MessageModel
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Struct that provides an interface to select the text to search in identity query results.
public protocol IdentityQueryResultsSearchProtocol {

    /// Creates a IdentityQueryResultsSearch
    /// that can be used to get the predicates for the identities that fit in the search
    /// the fields used for the search are: Address and Name
    /// - Parameter searchTerms: Text to be searched inside the identity
    init(searchTerm searchTerms: String)

    ///predicate related to the text searched is generated on demand.
    var predicate: NSPredicate { get }
}

public struct IdentityQueryResultsSearch: IdentityQueryResultsSearchProtocol {

    public init(searchTerm searchTerms: String) {
        self.searchTerm = searchTerms
    }

    private let searchTerm: String

    public var predicate: NSPredicate {
        get {
            return CdIdentity.PredicateFactory.addressOrUserNameContains(searchTerm: searchTerm)
        }
    }
}

// Mark: - Hashable

extension IdentityQueryResultsSearch: Hashable {
    public func hash(into hasher: inout Hasher) {
        // `predicate.hashValue` is returning an unexpected value, that's why we use description.
        hasher.combine(predicate.description)
    }
}

// Mark: - Equatable

extension IdentityQueryResultsSearch : Equatable {
    public static func ==(lhs: IdentityQueryResultsSearch, rhs: IdentityQueryResultsSearch) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
