//
//  MessagePredicate+Factory+KeySync.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.07.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// KeySync specific predicates.

extension Message.PredicateFactory {

    static public func isNotAutoConsumable() -> NSPredicate {
        return CdMessage.PredicateFactory.isNotAutoConsumable()
    }
}
