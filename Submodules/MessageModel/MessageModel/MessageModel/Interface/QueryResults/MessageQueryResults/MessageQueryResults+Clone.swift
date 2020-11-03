//
//  MessageQueryResults+Clone.swift
//  MessageModel
//
//  Created by Andreas Buff on 06.12.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

// MARK: - MessageQueryResults+Clone

extension MessageQueryResults {

    /// Creates a clone MessageQueryResults instance with the same folder, filter and search.
    /// Use if you need to share someone elses MessageQueryResults but want to be an additional
    /// delegate.
    /// - note: The createe has no delegate set and is not monitoring results yet.
    public func clone() -> MessageQueryResults {
        return MessageQueryResults(withFolder: folder,
                                   filter: filter,
                                   search: search,
                                   rowDelegate: nil,
                                   sectionDelegate: nil)
    }
}
