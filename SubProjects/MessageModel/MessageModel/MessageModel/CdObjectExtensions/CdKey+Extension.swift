//
//  CdKey+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import CoreData

extension CdKey {
    static func create(stringKey: String, context: NSManagedObjectContext) -> CdKey {
        let key = CdKey(context: context)
        key.fingerprint = stringKey
        return key
    }
}
