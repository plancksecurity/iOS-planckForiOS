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
        let predicate = CdClientCertificate.PredicateFactory.searchLabelInKeychain(label: label,
                                                                                   keychainUuid: keychainUuid)
        let rawSearchResult = CdClientCertificate.all(predicate: predicate,
                                                      in: context)
        let certificates = rawSearchResult as? [CdClientCertificate] ?? []
        return certificates.first
    }

    public override func validateForDelete() throws {
        ClientCertificateUtil().removeSecIdentityFromKeychain(of: self)
        try super.validateForDelete()
    }
}
