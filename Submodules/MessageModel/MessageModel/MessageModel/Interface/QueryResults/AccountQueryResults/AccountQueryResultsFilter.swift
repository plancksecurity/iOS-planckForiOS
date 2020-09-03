//
//  AccountQueryResultsFilter.swift
//  MessageModel
//
//  Created by Martin Brude on 01/09/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

///Struct that provides a interface to select which filters are enabled and how must be used.
public struct AccountQueryResultsFilter {

    public let mustBeIncludedInUnifiedFolders: Bool?

    public var predicate: NSPredicate {
        get {
            var finalPredicate = [NSPredicate]()
            if let _ = mustBeIncludedInUnifiedFolders {
                finalPredicate.append(CdAccount.PredicateFactory.isInUnified())
            }
            return NSCompoundPredicate(andPredicateWithSubpredicates: finalPredicate)
        }
    }

    public init(mustBeIncludedInUnifiedFolders: Bool? = nil) {
        self.mustBeIncludedInUnifiedFolders = mustBeIncludedInUnifiedFolders
    }
}
