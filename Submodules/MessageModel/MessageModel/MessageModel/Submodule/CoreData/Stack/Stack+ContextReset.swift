//
//  Stack+ContextReset.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 15.10.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import pEpIOSToolbox
import pEp4iosIntern

// MARK: - Tear Down
//!!!: move to test MM target somehow after pEp4IOS stopped using CD
extension Stack {

    /// Resets the Stack.
    /// MUST be used in tests only.
    /// - note: After calling this method, you MUST NOT use any privateConcurrentContext that has been created before calling this method.
    func reset() {
        objc_sync_enter(Stack.unitTestLock)
        defer { objc_sync_exit(Stack.unitTestLock) }
        guard MiscUtil.isUnitTest() else { fatalError("Not permited to use in production code.") }

        // A `reset(context:)` can involve a merge, which can crash a test.
        // Not wanted.
        stopReceivingContextNotifications()

        mainContext.hasBeenReset = true
        changePropagatorContext.hasBeenReset = true

        reset(context: mainContext)
        reset(context: changePropagatorContext)

        do {
            try loadCoreDataStack(storeType: NSInMemoryStoreType)
        } catch {
            fatalError("No Stack, no running app, sorry.")
        }
    }

    private func reset(context: NSManagedObjectContext) {
        for store in context.persistentStoreCoordinator?.persistentStores ?? [] {
            do {
                try context.persistentStoreCoordinator?.remove(store)
            } catch {
                Log.shared.errorAndCrash(error: error)
            }
        }
        context.performAndWait {
            context.reset()
        }
    }
}

extension Stack {

    /// Lock to synchronize reset() calls (in unit tests)
    static let unitTestLock = NSObject()
}

