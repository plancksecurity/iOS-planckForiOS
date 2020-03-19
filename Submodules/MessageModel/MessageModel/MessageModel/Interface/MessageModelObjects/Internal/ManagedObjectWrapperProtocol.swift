//
//  ManagedObjectWrapperProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

protocol ManagedObjectWrapperProtocol: Persistable, SessionAware {
    associatedtype T: NSManagedObject

    var moc: NSManagedObjectContext { get }
    var cdObject: T { get }
    init(cdObject: T, context: NSManagedObjectContext)
}

// MARK: - SessionAware

extension ManagedObjectWrapperProtocol {

    public var session: Session {
        return Session(context: moc)
    }
}

// MARK: - Persistable

extension ManagedObjectWrapperProtocol {

    public var isDeleted: Bool {
        return cdObject.isDeleted
    }

    public func save() {
        moc.saveAndLogErrors()
    }

    public func delete() {
        moc.delete(cdObject)
    }
}
