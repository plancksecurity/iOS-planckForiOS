//
//  CdMessageReference+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 13/05/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdMessageReference {
    struct PredicateFactory {
        static func with(messageID: String) -> NSPredicate {
            return NSPredicate(format: "%K = %@",
                               CdMessageReference.AttributeName.reference,
                               messageID)
        }
    }
}
