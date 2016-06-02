//
//  InMemoryCoreDataUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class InMemoryCoreDataUtil: ICoreDataUtil {
    let coreDataMerger = CoreDataMerger()

    public init() {
    }

    public lazy var managedObjectModel: NSManagedObjectModel = {
        // reuse the official one
        let model = CoreDataUtil.init().managedObjectModel
        return model
    }()

    /**
     An in-memory store coordinator for unit tests.
     */
    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let comp = "InMemoryCoreDataUtil"
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil,
                                                       URL: nil, options: nil)
            return coordinator
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "In memory store could not be created."

            dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: comp, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            Log.error(comp, error: wrappedError)
            abort()
        }
    }()

    /**
     An in-memory managed object context.
     */
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(
            concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        // Watch for merges
        self.coreDataMerger.managedObjectContext = managedObjectContext

        return managedObjectContext
    }()

    /**
     An in-memory object context for background operations in unit test.
     */
    public func confinedManagedObjectContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext.init(concurrencyType: .ConfinementConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    public func privateContext() -> NSManagedObjectContext {
        let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateMOC.parentContext = managedObjectContext
        return privateMOC
    }
}