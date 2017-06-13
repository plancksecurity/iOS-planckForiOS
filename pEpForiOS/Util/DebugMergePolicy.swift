//
//  CoreDataMergePolicy.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 09.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class DebugMergePolicy: NSMergePolicy {
    override func resolve(mergeConflicts list: [Any]) throws {
        if let mcList = list as? [NSMergeConflict] {
            try resolve(optimisticLockingConflicts: mcList)
        } else {
            try super.resolve(mergeConflicts: list)
        }
    }

    override func resolve(optimisticLockingConflicts list: [NSMergeConflict]) throws {
        let foundDiff = try mergeConflicts(originalError: nil, mergeConflicts: list)
        if foundDiff {
            try super.resolve(optimisticLockingConflicts: list)
        }
    }

    func mergeConflicts(originalError: Error?, mergeConflicts: [NSMergeConflict]) throws -> Bool {
        print("originalError: \(String(describing: originalError))")
        for mc in mergeConflicts {
            print("mc \(mc)")
            guard
                let objSnapshot = mc.objectSnapshot, let cachedSnapshot = mc.cachedSnapshot else {
                    print("No object snapshot or cached snapshot")
                    return true
            }
            if let persistedSnapshot = mc.persistedSnapshot {
                print("2. Between the cached state at the Persistent store coordinator and the external store (file, database, etc.).")
                return diff(dict1: cachedSnapshot, dict2: persistedSnapshot)
            } else {
                print("1. Between the Managed object context and its in-memory cached state at the Persistent store coordinator layer.")
                return diff(dict1: objSnapshot, dict2: cachedSnapshot)
            }
        }
        return true
    }

    func diff(dict1: [String:Any], dict2: [String:Any]) -> Bool {
        var keysDict1 = Set<String>()
        for k in dict1.keys {
            keysDict1.insert(k)
            guard let v1 = dict1[k], let v2 = dict2[k] else {
                print("key \(k) only in dict1")
                continue
            }
            let o1 = v1 as AnyObject
            print("Comparing \(k): \(o1)")
            if !o1.isEqual(v2) {
                print("*** Diff: \(k): \(v1) \(v2)")
                return true
            }
        }
        return false
    }
}
