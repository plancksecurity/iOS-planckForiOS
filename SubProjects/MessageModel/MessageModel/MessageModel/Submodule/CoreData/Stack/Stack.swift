//
// Stack.swift
//
//  Created by Andreas Buff on 03.07.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

import pEp4iosIntern

/// Our Core Data Stack
class Stack {

    // MARK: - Singleton

    static private(set) var shared = Stack() {
        didSet {
            guard MiscUtil.isUnitTest() else {
                fatalError("This dirty trick is allowed in unit tests only")
            }
        }
    }

    private init() {
        do {
            if MiscUtil.isUnitTest() {
                // Uses in memory store for tests. No file -> no need to bother with file.
                try loadCoreDataStack(storeType: NSInMemoryStoreType)
            } else {
                try loadCoreDataStack()
            }
        } catch {
            fatalError("No Stack, no running app, sorry.")
        }
    }

    deinit {
        stopReceivingContextNotifications()
    }

    // MARK: - Properties

    private var model: NSManagedObjectModel?
    private var coordinator: NSPersistentStoreCoordinator?

    private(set) var mainContext: NSManagedObjectContext!

    /// Context that propagates changes to:
    /// * private concurrent contexts
    /// * anyone who reads from it
    ///
    /// Use as parent for one time concurrent contexts and for NSFetchedResultsControllers that
    /// listen for query changes in background.
    ///
    /// - note: This is read only! You MUST NOT write nor save this context.
    ///         Saving it will crash in DEBUG and do nothing in RELASE (you'll silently loose your
    ///         changes)
    private(set) var changePropagatorContext: NSManagedObjectContext!

    var newPrivateConcurrentContext: NSManagedObjectContext {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let createe = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        createe.parent = changePropagatorContext
        createe.name = "privateQueueConcurrent context created on \(Date())"
        createe.automaticallyMergesChangesFromParent = true
        createe.undoManager = nil
        createe.mergePolicy = Stack.objectWinsMergePolicy

        return createe
    }
}

// MARK: - Setup

extension Stack {

    /// Returns the final URL for the store with given name.
    ///
    /// - Parameter name: Filename for the .sqlite store.
    /// - Returns: File URL for the store with given name
    static private func storeURL(for name: String) -> URL {
        guard let directoryURL =
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier)
            else {
                fatalError("No DB, no app, sorry.")
        }
        let storeName = "\(name).sqlite"
        let storeUrl = directoryURL.appendingPathComponent(storeName)
        Log.shared.info("storeUrl: %@", storeUrl.absoluteString)
        return storeUrl
    }

    /// Loads Core Data Stack (creates new if it doesn't already exist) with given options (all
    /// options are optional).
    ///
    /// - NOTE:
    /// Default option for `managedObjectModel` is `NSManagedObjectModel.mergedModelFromBundles(nil)!`,
    /// custom may be provided by using `modelFromBundle:` method.
    ///
    /// Default option for `storeType` is `NSSQLiteStoreType`
    ///
    /// Default option for `storeURL` is `bundleIdentifier + ".sqlite"` inside
    /// `applicationDocumentsDirectory`, custom may be provided by using `storeURLForName:` method.
    ///
    /// - parameter managedObjectModel: Managed object model for Core Data Stack.
    /// - parameter storeType: Store type for Persistent Store creation.
    /// - parameter configuration: Configuration for Persistent Store creation.
    /// - parameter storeURL: File URL for Persistent Store creation.
    /// - parameter options: Options for Persistent Store creation.
    ///
    /// - returns: Throws error if something went wrong.
    private func loadCoreDataStack(managedObjectModel: NSManagedObjectModel = defaultManagedObjectModel,
                           storeType: String = NSSQLiteStoreType,
                           configuration: String? = nil,
                           storeURL: URL? = nil,
                           options: [AnyHashable : Any]? = defaultOptions) throws {
        model = managedObjectModel

        if MiscUtil.isUnitTest() {
            try configureStoreCoordinator(model: managedObjectModel,
                                          type: storeType,
                                          configuration: configuration,
                                          url: (storeType == NSInMemoryStoreType) ? nil : storeURL, // Use in memory or given URL. Do NOT use defaultURL. It uses an shared (app group) directory that is not available in tests
                                          options: options)
        } else {
            let url = storeURL ?? Stack.defaultURL
            try configureStoreCoordinator(model: managedObjectModel,
                                          type: storeType,
                                          configuration: configuration,
                                          url: url,
                                          options: options)

        }
        configureManagedObjectContexts()
        startReceivingContextNotifications()

    }

    private func configureManagedObjectContexts() {
        guard coordinator != nil else {
            Log.shared.errorAndCrash("We MUST have a cooridinator @ this point")
            return
        }
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = coordinator
        mainContext.name = "mainContext"
        mainContext.undoManager = nil
        mainContext.mergePolicy = Stack.objectWinsMergePolicy

        changePropagatorContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        changePropagatorContext.persistentStoreCoordinator = coordinator
        changePropagatorContext.name = "changePropagatorContext"
        changePropagatorContext.automaticallyMergesChangesFromParent = true
        changePropagatorContext.undoManager = nil
        changePropagatorContext.mergePolicy = Stack.objectWinsMergePolicy
    }

    private func configureStoreCoordinator(model: NSManagedObjectModel,
                                           type: String,
                                           configuration: String?,
                                           url: URL?,
                                           options: [AnyHashable : Any]?) throws {
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator?.addPersistentStore(ofType: type,
                                            configurationName: configuration,
                                            at: url,
                                            options: options)
    }
}

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

// MARK: - Merge Contexts

extension Stack {

    private func mergeChanges(from notification: Notification, in context: NSManagedObjectContext) {
        if MiscUtil.isUnitTest() {
            objc_sync_enter(Stack.unitTestLock)
            context.perform {
                if !context.hasBeenReset {
                    context.mergeChanges(fromContextDidSave: notification)
                }
            }
            objc_sync_exit(Stack.unitTestLock)
        } else {
            context.perform {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }
    }

    private func startReceivingContextNotifications() {
        let center = NotificationCenter.default

        // Contexts Sync
        let didSave = #selector(Stack.contextDidSave(_:))
        let didSaveName = NSNotification.Name.NSManagedObjectContextDidSave
        center.addObserver(self, selector: didSave, name: didSaveName, object: mainContext)
        center.addObserver(self, selector: didSave, name: didSaveName, object: changePropagatorContext)
    }

    private func stopReceivingContextNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Sync

    @objc
    private func contextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext  else {
            Log.shared.errorAndCrash("No context")
            return
        }

        let contextToRefresh: NSManagedObjectContext
        if context == mainContext {
            contextToRefresh = changePropagatorContext
        } else if context == changePropagatorContext {
            contextToRefresh = mainContext
        } else {
            // It's an independent context. Do nothing.
            return
        }
        mergeChanges(from: notification, in: contextToRefresh)
    }
}

extension NSManagedObjectContext {

    /// Synchronously saves itself and alr other required contexts.
    func saveAndLogErrors() {
        internalSaveAndLogErrors()
    }

    private func internalSaveAndLogErrors(alreadyCleanedDanglingObjects: Bool = false) {
        if !hasChanges {
            return
        }
        do {
            if self === Stack.shared.mainContext {
                try save()
            } else if self === Stack.shared.changePropagatorContext {
                Log.shared.errorAndCrash("changePropagatorContext is read only, You MUST NOT save it")
            } else {
                // Is private concurrent. Save it.
                try save()
                // Bubble the changes up the until main.
                // Save change propagator ...
                try saveContextCorrectly(context: Stack.shared.changePropagatorContext)
                // ... and main
                DispatchQueue.main.async {
                    Stack.shared.mainContext.saveAndLogErrors()
                }
            }
        } catch {
            Log.shared.error(error: error)
            guard !alreadyCleanedDanglingObjects else {
                return
            }
            var cleanedUpSomething = false
            let allImapFields: [CdImapFields] = (CdImapFields.all(in: self) as? [CdImapFields]) ?? []
            for cdImapField in allImapFields {
                if cdImapField.message == nil ||
                    cdImapField.localFlags == nil ||
                    cdImapField.serverFlags == nil
                {
                    Log.shared.errorAndCrash("Dangling object found! Find where this was created and fix it please!")
                    self.delete(cdImapField)
                    cleanedUpSomething = true
                    continue
                }
            }
            if cleanedUpSomething {
                // We found a dangling object potentionally causing the throw and deleted it.
                // Lets try again!
                internalSaveAndLogErrors(alreadyCleanedDanglingObjects: true)
            }
        }
    }

    private func saveContextCorrectly(context: NSManagedObjectContext) throws {
        var resultError: Error? = nil
        context.performAndWait {
            if !context.hasChanges {
                return
            }
            do {
                try context.save()
            } catch {
                resultError = error
            }
        }
        if let er = resultError {
            throw(er)
        }
    }
}

// MARK: - Defaults

extension Stack {

    static private var defaultManagedObjectModel: NSManagedObjectModel {
        let messageModelBundle = Bundle(for: self)
        let modelURL = messageModelBundle.url(forResource: "MessageModel", withExtension: "momd")!
        let objectModel = NSManagedObjectModel(contentsOf: modelURL)!
        return objectModel
    }

    // MARK: - Defaults

    /// Must be hard-coded (instead of using the dynamic Bundle.main.bundleIdentifier
    /// as before) to ensure that both app and extension (which would have different bundle identifiers)
    /// use the same value. Must be "security.pEp" to be backwards-compatible with previous versions
    /// of the app where the bundle identifier was used.
    static private var defaultName = kDatabaseName

    static private var defaultURL: URL {
        return storeURL(for: defaultName)
    }

    static private var defaultOptions: [String:Bool] {
        return [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true]
    }

    static private var objectWinsMergePolicy: NSMergePolicy {
        return NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
    }
}
