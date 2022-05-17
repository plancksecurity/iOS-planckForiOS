//
//  ImapFlags.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class ImapFlags: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdImapFlags
    let moc: NSManagedObjectContext
    let cdObject: T

    // MARK: - Life Cycle

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Forwarded Getters & Setters

    public var answered: Bool {
        get {
            return cdObject.flagAnswered
        }
        set {
            cdObject.flagAnswered = newValue
        }
    }

    public var draft: Bool {
        get {
            return cdObject.flagDraft
        }
        set {
            cdObject.flagDraft = newValue
        }
    }

    public var flagged: Bool {
        get {
            return cdObject.flagFlagged
        }
        set {
            cdObject.flagFlagged = newValue
        }
    }

    public var recent: Bool {
        get {
            return cdObject.flagRecent
        }
        set {
            cdObject.flagRecent = newValue
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

    public var deleted: Bool {
        get {
            return cdObject.flagDeleted
        }
        set {
            cdObject.flagDeleted = newValue
        }
    }
}

// MARK: - Utils

//!!!: extract
extension ImapFlags {

    public func rawFlagsAsShort() -> Int16 {
        return ImapFlagsUtility.int16(answered: answered,
                                      draft: draft,
                                      flagged: flagged,
                                      recent: recent,
                                      seen: seen,
                                      deleted: deleted)
    }
}
