//
//  CdMessageReference+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//
import CoreData

extension CdMessageReference {
    static public func create(messageID: String,
                              context: NSManagedObjectContext) -> CdMessageReference {
        return CdMessageReference.firstOrCreate(attribute: "reference",
                                                value: messageID,
                                                in: context)
    }
}
