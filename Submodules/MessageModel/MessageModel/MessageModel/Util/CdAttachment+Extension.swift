//
//  CdAttachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

extension CdAttachment {

    public override func validateForInsert() throws {
        if mimeType == nil {
            mimeType = MimeTypeUtils.MimeType.defaultMimeType.rawValue
        }
        try super.validateForInsert()
    }
    /**
     When removing attachments from a message, there will be the old attachments with
     message = nil in the system, which will trigger a NSValidationException.
     Therefore, call this function.
     */
    public static func deleteOrphans(context: NSManagedObjectContext) {
        let p = CdAttachment.PredicateFactory.itemsWithoutAnyRelationshipMessage()
        if let orphans = CdAttachment.all(predicate: p, in: context ) as? [CdAttachment] {
            for o in orphans {
                context.delete(o)
            }
        }
    }

    //!!!: move to app
    public override var description: String {
        let s = NSMutableString()
        if let fn = fileName {
            s.append(", \(fn)")
        }
        if let ct = mimeType {
            s.append(", \(ct)")
        }
        return String(s)
    }

    public override var debugDescription: String {
        return description
    }
}
