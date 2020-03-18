//
//  ExtryKey.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

public class ExtraKey: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdExtraKey
    let moc: NSManagedObjectContext
    let cdObject: T

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Forwarded Getters & Setters

    /// The fingerprint of the key
    public var fingerprint: String {
        return cdObject.fingerprint!
    }
}
