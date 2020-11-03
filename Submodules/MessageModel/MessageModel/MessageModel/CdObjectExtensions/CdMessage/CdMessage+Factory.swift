//
//  CdMessage+Factory.swift
//  MessageModel
//
//  Created by Andreas Buff on 17.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

// MARK: - CdMessage+Factory

extension CdMessage {

    /// Inserts a new CdMessage and preconfigures it to be ready to use as incomming message.
    static func newIncomingMessage(context: NSManagedObjectContext) -> CdMessage {
        let createe = CdMessage(context: context)
        createe.needsDecrypt = true
        return createe
    }

    /// Inserts a new CdMessage and preconfigures it to be ready to use as outgoing message.
    static func newOutgoingMessage(context: NSManagedObjectContext) -> CdMessage {
        let createe = CdMessage(context: context)
        createe.uuid = MessageID.generateUUID()
        createe.sent = Date()
        return createe
    }
}

