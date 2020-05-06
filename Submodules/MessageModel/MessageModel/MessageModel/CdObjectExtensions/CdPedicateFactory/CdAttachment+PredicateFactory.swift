//
//  CdAttachment+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 06/05/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdAttachment {
    struct PredicateFactory {
        static public func with(filename: String) -> NSPredicate {
            return NSPredicate(format: "%K = %@",
                               CdAttachment.AttributeName.fileName,
                               filename)
        }
    }
}
