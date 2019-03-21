//
//  CdAttachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdAttachment {
    /**
     When removing attachments from a message, there will be the old attachments with
     message = nil in the system, which will trigger a NSValidationException.
     Therefore, call this function.
     */
    public static func deleteOrphans() {
        if let orphans = CdAttachment.all(
            predicate: NSPredicate(format: "message = nil")) as? [CdAttachment] {
            for o in orphans {
                o.delete()
            }
        }
    }

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
