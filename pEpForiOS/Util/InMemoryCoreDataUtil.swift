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
    public lazy var managedObjectModel: NSManagedObjectModel = {
        // reuse the official one
        let model = CoreDataUtil.init().managedObjectModel
        return model
    }()

    /**
     An in-memory store coordinator for unit tests.
     */
    public lazy var testPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    }()

    /**
     An in-memory managed object context.
     */
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.testPersistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(
            concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    /**
     An in-memory object context for background operations in unit test.
     */
    public func confinedManagedObjectContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext.init(concurrencyType: .ConfinementConcurrencyType)
        context.persistentStoreCoordinator = self.testPersistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}