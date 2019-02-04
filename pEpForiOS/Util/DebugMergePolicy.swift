//
//  CoreDataMergePolicy.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 09.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData
import pEpUtilities

class DebugMergePolicy: NSMergePolicy {
    override func resolve(mergeConflicts list: [Any]) throws {
        if let mcs = list as? [NSMergeConflict] {
            resolve(mergeConflicts: mcs)
        } else {
            try super.resolve(mergeConflicts: list)
        }
    }

    override func resolve(optimisticLockingConflicts list: [NSMergeConflict]) throws {
        resolve(mergeConflicts: list)
    }

    func resolve(mergeConflicts: [NSMergeConflict]) {
        for mc in mergeConflicts {
            let conflictingObjects = mc.conflictingKeyPaths()
            if !conflictingObjects.isEmpty {
                var logString = "Merge Conflict: \(mc.sourceObject.objectID)\n"
                if mc.isType1 {
                    logString += "Between the Managed object context and its in-memory cached state at the Persistent store coordinator layer."
                } else if mc.isType2 {
                    logString += "Between the cached state at the Persistent store coordinator and the external store (file, database, etc.)."
                } else {
                    logString += "Unknown type."
                }
                for c in conflictingObjects {
                    logString += "\n* \(c.keyPath):\n\(String(describing: c.o1))\n->\n\(String(describing: c.o2))"
                }
                Logger.utilLogger.error("%{public}@", logString)
            }
        }
    }
}
