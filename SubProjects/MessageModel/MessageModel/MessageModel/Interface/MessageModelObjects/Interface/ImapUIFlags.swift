//
//  ImapUIFlags.swift
//  MessageModel
//
//  Created by Martín Brude on 20/4/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class ImapUIFlags: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdImapUIFlags
    let moc: NSManagedObjectContext
    let cdObject: T

    // MARK: - Life Cycle

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Forwarded Getters & Setters

    public var flagged: Bool {
        get {
            return cdObject.flagFlagged
        }
        set {
            cdObject.flagFlagged = newValue
        }
    }

    public var seen: Bool {
        get {
            return cdObject.flagSeen
        }
        set {
            cdObject.flagSeen = newValue
        }
    }
}
