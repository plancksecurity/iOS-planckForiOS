//
//  AccountQueryResultFilter.swift
//  MessageModel
//
//  Created by Martin Brude on 27/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox


///Struct that provides an interface to select which filters are enabled and how must be used.
public struct AccountQueryResultsFilter {
    public let mustBeIncludedInUnifiedFolder: Bool?
    public let address: String?
    public let identity : CdIdentity?

    ///All the values of the filter will be used to calculate the predicate
    ///The compoundPredicate will be an or with the subpredicates and will be returnd as a predicate
    public var predicate: NSPredicate {
        get {
            var attributedPredicates = [NSPredicate]()
            if let address = address {
                attributedPredicates.append(CdAccount.PredicateFactory.by(address: address))
            }
            if let mustBeIncludedInUnifiedFolder = mustBeIncludedInUnifiedFolder, mustBeIncludedInUnifiedFolder {
                attributedPredicates.append(CdAccount.PredicateFactory.isInUnified())
            }
            if let identity = identity {
                attributedPredicates.append(CdAccount.PredicateFactory.belongingToIdentity(identity: identity))
            }
            return NSCompoundPredicate(andPredicateWithSubpredicates: attributedPredicates)
        }
    }

    ///Creates a MessageQueryResultsFilter
    ///that can be used to get the predicates for the different filters setted.
    ///
    /// - Parameters:
    ///   - mustBeIncludedInUnifiedFolder: handle the flagged value:
    public init(mustBeIncludedInUnifiedFolder: Bool? = nil,
                address: String? = nil,
                identity: CdIdentity? = nil) {
        self.mustBeIncludedInUnifiedFolder = mustBeIncludedInUnifiedFolder
        self.address = address
        self.identity = identity
    }

    /// XXXX what's this for?
//    public func account(at row: Int) -> Account? {
//        return nil
//    }
}

// Mark: - Hashable

extension AccountQueryResultsFilter: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(predicate.description)
    }
}

// Mark: - Equatable

extension AccountQueryResultsFilter : Equatable {
    public static func ==(lhs: AccountQueryResultsFilter, rhs: AccountQueryResultsFilter) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Convenience

extension AccountQueryResultsFilter {

    /// XXXX what's an enabled account?
    public var numEnabledAccounts: Int {
        return 0
    }
}
