//
//  CdAttachment+PEPAttachment.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCAdapterFramework

extension CdAttachment {
    static func from(pEpAttachment: PEPAttachment,
                     parentMessage: CdMessage,
                     inContext: NSManagedObjectContext) -> CdAttachment {
        let cdAtt = CdAttachment(context: inContext)

        cdAtt.message = parentMessage
        cdAtt.data = pEpAttachment.data
        cdAtt.fileName = pEpAttachment.filename
        cdAtt.mimeType = pEpAttachment.mimeType
        cdAtt.contentDispositionTypeRawValue = Attachment.ContentDispositionType.from(
            contentDisposition: pEpAttachment.contentDisposition).rawValue
        parentMessage.addToAttachments(cdAtt)

        return cdAtt
    }
}
