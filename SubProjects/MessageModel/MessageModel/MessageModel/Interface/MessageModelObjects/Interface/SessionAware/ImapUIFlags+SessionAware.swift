//
//  ImapUIFlags+SessionAware.swift
//  MessageModel
//
//  Created by Martín Brude on 26/4/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import CoreData

extension ImapUIFlags: SessionAware {

    public typealias MMO = ImapUIFlags

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
