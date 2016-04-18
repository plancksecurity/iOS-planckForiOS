//
//  BaseManagedObject.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class BaseManagedObject: NSManagedObject {
    static let comp = "BaseManagedObject"

    static func singleEntityWithName(name: String,
                                     predicate: NSPredicate,
                                     context: NSManagedObjectContext) -> NSManagedObject? {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        do {
            let objs = try context.executeFetchRequest(fetch)
            if objs.count == 1 {
                return objs[0] as? NSManagedObject
            } else if objs.count == 0 {
                return nil
            } else {
                Log.warn(comp, "Several objects (\(name)) found for predicate: \(predicate)")
                return objs[0] as? NSManagedObject
            }
        } catch let err as NSError {
            Log.error(comp, error: err)
        }
        return nil
    }

    static func entitiesWithName(name: String,
                                 predicate: NSPredicate,
                                 context: NSManagedObjectContext) -> [NSManagedObject]? {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        do {
            let objs = try context.executeFetchRequest(fetch)
            return objs as? [NSManagedObject]
        } catch let err as NSError {
            Log.error(comp, error: err)
        }
        return nil
    }

}