//
//  CdAttachment+Clone.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdAttachment {
    /**
     Clones this object.

     - Note: The (inverse) relationship message is not copied.
     */
    public func clone(context: NSManagedObjectContext) -> CdAttachment {
        let att = CdAttachment(context: context)

        att.assetUrl = assetUrl
        att.contentDispositionTypeRawValue = contentDispositionTypeRawValue
        att.data = data
        att.fileName = fileName
        att.mimeType = mimeType

        return att
    }
}
