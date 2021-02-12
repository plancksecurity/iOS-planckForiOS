//
//  CdAttachment+PEPAttachment.swift
//  MessageModel
//
//  Created by Andreas Buff on 16.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

// MARK: - CdAttachment+PEPAttachment.swift

extension CdAttachment {

    var pEpAttachment: PEPAttachment  {
        let attachment = PEPAttachment(data: data ?? Data())
        attachment.filename = fileName
        attachment.mimeType = mimeType
        attachment.contentDisposition = PEPContentDisposition(rawValue: Int32(contentDispositionTypeRawValue)) ?? PEPContentDisposition.attachment 
        return attachment
    }

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
