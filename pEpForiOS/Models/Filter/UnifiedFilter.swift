//
//  UnifiedFilter.swift
//  MessageModel
//
//  Created by Xavier Algarra on 02/10/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import MessageModel

public class UnifiedFilter: FilterBase {
    public override var predicates: [NSPredicate] {
        get {
            return [CdMessage.PredicateFactory.isInInbox(),
                    CdMessage.PredicateFactory.existingMessages()]
        }
    }

    public override var title: String {
        get {
            return NSLocalizedString("", comment: "No title for Unified filter")
        }
    }

    public override func isUnified() -> Bool {
        return true
    }

    public override func fulfillsFilter(message: Message) -> Bool {
        return message.parent.folderType == .inbox &&
            message.targetFolder == nil &&
            !(message.imapFlags?.deleted ?? false)
    }

    public override var hashValue: Int {
        get {
            let hashee = predicates.reduce(into: title) { (result, predicate) in
                result += predicate.description
            }
            return hashee.hashValue

        }
    }

    public override func isEqual(filter: FilterBase) -> Bool {
        guard let _ = filter as? UnifiedFilter else {
            return false
        }
        return filter.hashValue == hashValue
    }
}
