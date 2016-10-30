//
//  CoreDataUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public protocol ICoreDataUtilOld {
    /**
     - returns: The one and only main context, confined to the main thread/queue.
     */
    var managedObjectContext: NSManagedObjectContext { get }

    /**
     - Returns: Another context that's suitable for background tasks, confined to the
     thread/queue it was called on.
     - Note: Since that is getting deprecated, and can cause problems,
     please prefer `privateContext`.
     */
    func confinedManagedObjectContext() -> NSManagedObjectContext

    /**
     - Returns: A context of type `.PrivateQueueConcurrencyType`
     */
    func privateContext() -> NSManagedObjectContext
}

open class CoreDataMerger {
    var saveObserver: NSObjectProtocol!
    var managedObjectContext: NSManagedObjectContext?

    public init() {
        saveObserver = NotificationCenter.default.addObserver(
        forName: NSNotification.Name.NSManagedObjectContextDidSave, object: nil,
        queue: OperationQueue.main) {
            [unowned self] notification in
            if let context = self.managedObjectContext {
                self.mergeContexts(notification, context: context)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(saveObserver)
    }

    open func mergeContexts(_ notification: Notification, context: NSManagedObjectContext) {
        context.mergeChanges(fromContextDidSave: notification)
    }
}

open class CoreDataUtilOld: ICoreDataUtilOld {
    static let comp = "CoreDataUtil"

    let coreDataMerger = CoreDataMerger()

    // MARK: - Core Data stack

    open lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "net.pep-security.apps.pEpForiOS" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory,
                                                                   in: .userDomainMask)
        return urls[urls.count-1]
    }()

    open lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "pEpForiOS", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    open lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        return self.createPersistentStoreCoordinator()
    }()

    func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(
            "SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
                                                       at: url, options: nil)
        } catch let error as NSError {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: CoreDataUtilOld.comp, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            Log.error(component: CoreDataUtilOld.comp, error: wrappedError)
            abort()
        }

        return coordinator
    }

    open lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(
            concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        // Watch for merges
        self.coreDataMerger.managedObjectContext = managedObjectContext

        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    open func saveContext () {
        CoreDataUtilOld.saveContext(managedObjectContext)
    }

    // MARK: - Extensions

    open static func saveContext(_ managedObjectContext: NSManagedObjectContext) {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                Log.error(component: CoreDataUtilOld.comp, error: nserror)
                abort()
            }
        }
    }

    open func confinedManagedObjectContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext.init(concurrencyType: .confinementConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    open func privateContext() -> NSManagedObjectContext {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        return privateMOC
    }
}
