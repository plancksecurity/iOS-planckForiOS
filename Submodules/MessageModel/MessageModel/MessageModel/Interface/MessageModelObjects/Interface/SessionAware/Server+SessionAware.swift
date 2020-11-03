//
//  Server+SessionAware.swift
//  MessageModel
//
//  Created by Andreas Buff on 03.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

// MARK: - SessionAware

// This is ugly, because it is duplicated for *all* MessageModelObject[Protocol]s.
// I did it because I could not find a way to make it usable for clients without making the
// `cdObject` property visible (which MUST NOT happen).
extension Server: SessionAware {

    public typealias MMO = Server

    public func safeForSession(_ session: Session) -> MMO {
        return MMO.makeSafe(self, forSession: session)
    }

    public static func makeSafe(_ object: MMO, forSession session: Session) -> MMO {
        // Get ObjID without violating CD threading rules ...
        var id: NSManagedObjectID!

        id = object.cdObject.objectID

        // ... and get the object from the target MOC by ID.
        var safeCdObject: T!
        var result: MMO!
        session.moc.performAndWait {
            safeCdObject = (session.moc.object(with: id) as! T)
            result = MMO(cdObject: safeCdObject, context: session.moc)
        }
        return result
    }

    public static func makeSafe(_ objects: [MMO], forSession session: Session) -> [MMO] {
        var createe = [MMO]()
        for object in objects {
            createe.append(makeSafe(object, forSession: session))
        }
        return createe
    }

    public static func newObject(onSession session: Session) -> MMO {
        let moc = session.moc
        let cdCreatee = T(context: moc)
        return MMO(cdObject: cdCreatee, context: moc)
    }
}
