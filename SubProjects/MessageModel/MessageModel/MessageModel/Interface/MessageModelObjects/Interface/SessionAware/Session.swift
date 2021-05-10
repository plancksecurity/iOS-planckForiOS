//
//  Session.swift
//  MessageModel
//
//  Created by Andreas Buff on 28.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

//!!!: docs!
public protocol SessionProtocol {
    func perform(block: @escaping ()->())
    func performAndWait(block: @escaping ()->())
    func commit()
    func rollback()
}

public struct Session {
    /// Session to use on the main queue
    static public var main: Session {
        return Session(context: Stack.shared.mainContext)
    }

    let moc: NSManagedObjectContext

    /// Creates a new session.
    public init() {
        let moc = Stack.shared.newPrivateConcurrentContext
        self.init(context: moc)
    }

    // MARK: - --

    init(context: NSManagedObjectContext) {
        self.moc = context
    }
}

extension Session: SessionProtocol {
    public func perform(block: @escaping ()->()) {
        moc.perform {
            block()
        }
    }

    public func performAndWait(block: @escaping ()->()) {
        moc.performAndWait {
            block()
        }
    }

    public func commit() {
        moc.saveAndLogErrors()
    }

    public func rollback() {
        moc.rollback()
    }
}
