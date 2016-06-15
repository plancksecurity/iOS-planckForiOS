//
//  CoreDataUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public protocol ICoreDataUtil {
    /**
     - returns: The one and only main context, confined to the main thread/queue.
     */
    var managedObjectContext: NSManagedObjectContext { get }

    /**
     - Returns: Another context that's suitable for background tasks, confined to the
     thread/queue it was called on.
     */
    func confinedManagedObjectContext() -> NSManagedObjectContext

    /**
     - Returns: A context of type `.PrivateQueueConcurrencyType`
     */
    func privateContext() -> NSManagedObjectContext
}

public class CoreDataMerger {
    var saveObserver: NSObjectProtocol!
    var managedObjectContext: NSManagedObjectContext?

    public init() {
        saveObserver = NSNotificationCenter.defaultCenter().addObserverForName(
        NSManagedObjectContextDidSaveNotification, object: nil,
        queue: NSOperationQueue.mainQueue()) {
            [unowned self] notification in
            if let context = self.managedObjectContext {
                self.mergeContexts(notification, context: context)
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(saveObserver)
    }

    public func mergeContexts(notification: NSNotification, context: NSManagedObjectContext) {
        context.mergeChangesFromContextDidSaveNotification(notification)
    }
}

public class CoreDataUtil: ICoreDataUtil {
    static let comp = "CoreDataUtil"

    let coreDataMerger = CoreDataMerger()

    // MARK: - Core Data stack

    public lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "net.pep-security.apps.pEpForiOS" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory,
                                                                   inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    public lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("pEpForiOS", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        return self.createPersistentStoreCoordinator()
    }()

    func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(
            "SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil,
                                                       URL: url, options: nil)
        } catch let error as NSError {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: CoreDataUtil.comp, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            Log.error(CoreDataUtil.comp, error: wrappedError)
            abort()
        }

        return coordinator
    }

    public lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(
            concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        // Watch for merges
        self.coreDataMerger.managedObjectContext = managedObjectContext

        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    public func saveContext () {
        CoreDataUtil.saveContext(managedObjectContext: managedObjectContext)
    }

    // MARK: - Extensions

    public static func saveContext(managedObjectContext managedObjectContext: NSManagedObjectContext) {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                Log.error(CoreDataUtil.comp, error: nserror)
                abort()
            }
        }
    }

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
