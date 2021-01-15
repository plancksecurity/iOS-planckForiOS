//
//  CdAttachment+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension CdAttachment {

    func attachment() -> Attachment? {
        return MessageModelObjectUtils.getAttachment(fromCdAttachment: self)
    }
}

// MARK: - FETCHING

extension CdAttachment {
    static func by(filename: String, context: NSManagedObjectContext) -> CdAttachment? {
        return CdAttachment.first(predicate: NSPredicate(format: "%K = %@",
                                                         CdAttachment.AttributeName.fileName,
                                                         filename), in: context)
    }
}
