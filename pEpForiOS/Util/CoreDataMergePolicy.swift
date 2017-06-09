//
//  CoreDataMergePolicy.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 09.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class CoreDataMergePolicy: NSMergePolicy {
    override func resolve(mergeConflicts list: [Any]) throws {
        do {
            try super.resolve(mergeConflicts: list)
        } catch (let error) {
            guard let mcList = list as? [NSMergeConflict] else {
                throw error
            }
            try mergeConflicts(error: error, mergeConflicts: mcList)
        }
    }

    override func resolve(optimisticLockingConflicts list: [NSMergeConflict]) throws {
        do {
            try super.resolve(optimisticLockingConflicts: list)
        } catch (let error) {
            try mergeConflicts(error: error, mergeConflicts: list)
        }
    }

    func mergeConflicts(error: Error, mergeConflicts: [NSMergeConflict]) throws {
        print("error: \(error)")
        for mc in mergeConflicts {
            print("mc \(mc)")
        }
    }
}
