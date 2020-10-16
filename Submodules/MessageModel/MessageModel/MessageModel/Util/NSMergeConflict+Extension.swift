//
//  NSMergeConflict+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.06.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import pEpIOSToolbox

//!!!: afaics this is used unly in one test. If so rm test and code

extension NSMergeConflict {
    public struct ConflictingKeyPath {
        public let keyPath: String
        public let o1: Any?
        public let o2: Any?
    }

    /**
     Between the Managed object context and its in-memory cached state
     at the Persistent store coordinator layer.
     */
    var isType1: Bool {
        return cachedSnapshot != nil && persistedSnapshot == nil
    }

    /**
     Between the cached state at the Persistent store coordinator
     and the external store (file, database, etc.).
     */
    var isType2: Bool {
        return cachedSnapshot != nil && persistedSnapshot != nil
    }

    /**
     Diffs the objects in conflict.
     - Returns: The keys that had conflicts.
     */
    public func conflictingKeyPaths() -> [ConflictingKeyPath] {
        var keys = [String]()
        if let cached = cachedSnapshot {
            for k in cached.keys {
                keys.append(k)
            }
            if isType1 {
                return diff(
                    sourceObject: sourceObject,
                    dict1: sourceObject.dictionaryWithValues(forKeys: keys),
                    dict2: cached)
            } else if isType2, let persisted = persistedSnapshot {
                return diff(sourceObject: sourceObject, dict1: cached, dict2: persisted)
            }
        }
        return []
    }

    func diff(sourceObject: NSManagedObject,
              dict1: [String: Any],
              dict2: [String: Any],
              handledObjects: Set<NSManagedObjectID> = Set<NSManagedObjectID>(),
              keyPath: String? = nil) -> [ConflictingKeyPath] {
        guard let moc = sourceObject.managedObjectContext else {
            Log.shared.errorAndCrash("The object to diff has been deleted from contex")
            return []
        }
        if handledObjects.contains(sourceObject.objectID) {
            return []
        }
        var newHandledObjects = Set<NSManagedObjectID>(handledObjects)
        newHandledObjects.insert(sourceObject.objectID)

        let propertyNameDelimiter = "."

        var conflictingKeys = [ConflictingKeyPath]()

        for k in dict1.keys {
            var currentCompleteKeyPath = k
            if keyPath != nil {
                currentCompleteKeyPath = "\(keyPath!)\(propertyNameDelimiter)\(k)"
            }

            let o1 = dict1[k]
            let o2 = dict2[k]

            guard let obj1 = o1, let obj2 = o2 else {
                conflictingKeys.append(
                    ConflictingKeyPath(keyPath: currentCompleteKeyPath, o1: o1, o2: o2))
                continue
            }

            if
                let managed1 = retrieve(object: obj1, fromContext: moc),
                let managed2 = retrieve(object: obj2, fromContext: moc) {
                // recursion
                let propertyNames = managed1.allPropertyNames()
                let moreConflicts = diff(
                    sourceObject: managed1,
                    dict1: managed1.dictionaryWithValues(forKeys: propertyNames),
                    dict2: managed2.dictionaryWithValues(forKeys: propertyNames),
                    handledObjects: newHandledObjects,
                    keyPath: currentCompleteKeyPath)
                for c in moreConflicts {
                    let propertyName = currentCompleteKeyPath + propertyNameDelimiter + c.keyPath
                    conflictingKeys.append(
                        ConflictingKeyPath(keyPath: propertyName, o1: managed1, o2: managed2))
                }
            } else if let obj1 = o1, let obj2 = o2 {
                if !(obj1 as AnyObject).isEqual(obj2) {
                    conflictingKeys.append(
                        ConflictingKeyPath(keyPath: currentCompleteKeyPath, o1: obj1, o2: obj2))
                }
            }
         }

        return conflictingKeys
    }

    func retrieve(object: Any, fromContext: NSManagedObjectContext) -> NSManagedObject? {
        if let managedObject = object as? NSManagedObject {
            return managedObject
        }
        if let objectID = object as? NSManagedObjectID {
            return fromContext.object(with: objectID)
        }
        return nil
    }
}
