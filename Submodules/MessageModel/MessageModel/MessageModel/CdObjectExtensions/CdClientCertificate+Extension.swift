//
//  CdClientCertificate+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdClientCertificate {
    static func search(label: String,
                       keychainUuid: String,
                       context: NSManagedObjectContext) -> CdClientCertificate? {
        let predicate = NSPredicate(format: "%K = %@ and %K = %@",
                                    CdClientCertificate.AttributeName.label,
                                    label,
                                    CdClientCertificate.AttributeName.keychainUuid,
                                    keychainUuid)
        let rawSearchResult = CdClientCertificate.all(predicate: predicate, in: context)
        let certificates = rawSearchResult as? [CdClientCertificate] ?? []
        return certificates.first
    }
}
