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
            mimeType = MimeTypeUtils.MimesType.defaultMimeType.rawValue
        }
        try super.validateForInsert()
    }
    /**
     When removing attachments from a message, there will be the old attachments with
     message = nil in the system, which will trigger a NSValidationException.
     Therefore, call this function.
     */
    public static func deleteOrphans(context: NSManagedObjectContext) {
        let p = NSPredicate(format: "%K = nil",
                            CdAttachment.RelationshipName.message)
        if let orphans = CdAttachment.all(predicate: p, in: context ) as? [CdAttachment] {
            for o in orphans {
                context.delete(o)
            }
        }
    }

    //!!!: move to app
    override open var description: String {
        let s = NSMutableString()
        if let fn = fileName {
            s.append(", \(fn)")
        }
        if let ct = mimeType {
            s.append(", \(ct)")
        }
        return String(s)
    }

    override open var debugDescription: String {
        return description
    }
}
