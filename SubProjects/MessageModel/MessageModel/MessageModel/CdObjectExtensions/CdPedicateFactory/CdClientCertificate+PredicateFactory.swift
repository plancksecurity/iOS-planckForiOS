//
//  CdClientCertificate+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 13/05/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdClientCertificate {
    struct PredicateFactory {
        static func searchLabelInKeychain(label: String,
                                                 keychainUuid: String) -> NSPredicate {
            return NSPredicate(format: "%K = %@ and %K = %@",
            CdClientCertificate.AttributeName.label,
            label,
            CdClientCertificate.AttributeName.keychainUuid,
            keychainUuid)
        }
    }
}
