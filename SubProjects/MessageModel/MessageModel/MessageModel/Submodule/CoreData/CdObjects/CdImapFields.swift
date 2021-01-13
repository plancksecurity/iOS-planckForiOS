//
//  CdImapFields.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

@objc(CdImapFields)
public class CdImapFields: NSManagedObject {
    func assureLocalFlagsNotNil(context: NSManagedObjectContext) {
        if localFlags == nil {
            localFlags = CdImapFlags(context: context)
        }
    }

    func assureServerFlagsNotNil(context: NSManagedObjectContext) {
        if serverFlags == nil {
            serverFlags = CdImapFlags(context: context)
        }
    }
}
