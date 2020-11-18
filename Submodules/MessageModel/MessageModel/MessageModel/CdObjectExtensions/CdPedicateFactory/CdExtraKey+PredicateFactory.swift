//
//  CdExtryKey+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension CdExtraKey {
    struct PredicateFactory {
        /// - returns: predicate for all CdExtraKeys with given FPR
        static func containing(fingerprinnt fpr: String) -> NSPredicate {
            return NSPredicate(format: "%K = %@", CdKey.AttributeName.fingerprint, fpr)
        }
    }
}
