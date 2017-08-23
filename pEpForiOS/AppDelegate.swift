//
//  AppDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let comp = "AppDelegate"

    var window: UIWindow?

    var appConfig: AppConfig?

    /** The SMTP/IMAP backend */
    var networkService: NetworkService?

    /**
     UI triggerable actions for syncing messages.
     */
    var messageSyncService: MessageSyncService?

    var application: UIApplication!

    let mySelfQueue = LimitedOperationQueue()

    lazy var appSettings = AppSettings()

    let sendLayerDelegate = DefaultUISendLayerDelegate()

    func applicationDirectory() -> URL? {
        let fm = FileManager.default
        let dirs = fm.urls(for: .libraryDirectory, in: .userDomainMask)
        return dirs.first
    }

    func dumpFontSizes() {
        let styles = [UIFontTextStyle.body, UIFontTextStyle.caption1, UIFontTextStyle.caption2,
                      UIFontTextStyle.footnote, UIFontTextStyle.headline,
                      UIFontTextStyle.subheadline]
        for sty in styles {
            let font = UIFont.preferredFont(forTextStyle: sty)
            print("\(sty) \(font)")
        }
    }

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.application = application
        application.setMinimumBackgroundFetchInterval(60.0 * 10)

        let pEpReInitialized = deleteManagementDBIfRequired()

        // Open the first session from the main thread and keep it open
        let session = PEPSession()

        let theMessageSyncService = MessageSyncService(
            parentName: #function, backgrounder: self, mySelfer: self)
        messageSyncService = theMessageSyncService
        appConfig = AppConfig(session: session, messageSyncService: theMessageSyncService)

        // set up logging for libraries
        MessageModelConfig.logger = Log.shared

        Appearance.pep()

        Log.warn(component: comp,
                 content: "Library url: \(String(describing: applicationDirectory()))")

        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }
        loadCoreDataStack()

        deleteAllFolders(pEpReInitialized: pEpReInitialized)

        kickOffMySelf()

        networkService = NetworkService(parentName: #function, backgrounder: self, mySelfer: self)
        networkService?.sendLayerDelegate = sendLayerDelegate
        CdAccount.sendLayer = networkService
        networkService?.start()

        DispatchQueue.global(qos: .userInitiated).async {
            AddressBook.checkAndTransfer()
        }

        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        self.application = application

        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.info(component: comp, content: "applicationDidEnterBackground")

        self.application = application
        kickOffMySelf()
    }

    func kickOffMySelf() {
        mySelfQueue.addOperation(MySelfOperation(parentName: #function, backgrounder: self))
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.application = application

        DispatchQueue.global(qos: .userInitiated).async {
            AddressBook.checkAndTransfer()
        }
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        self.application = application

        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.

        // Try to cleanly shutdown
        appConfig?.tearDownSession()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        networkService?.quickSync() { status in
            switch status {
            case .failed:
                completionHandler(.failed)
            case .fetchedData:
                completionHandler(.newData)
            case .noData:
                completionHandler(.noData)
            }
        }
    }

    func loadCoreDataStack() {
        let objectModel = MessageModelData.MessageModelData()
        do {
            try Record.loadCoreDataStack(managedObjectModel: objectModel)
        } catch {
            Log.error(component: comp, errorString: "Error while Loading DataStack")
        }
    }

    /**
     Removes all keys, and the management DB, when the user chooses so.
     - Returns: True if the pEp management DB was deleted, so further actions can be taken.
     */
    func deleteManagementDBIfRequired() -> Bool {
        if appSettings.shouldReinitializePepOnNextStartup {
            appSettings.shouldReinitializePepOnNextStartup = false
            let _ = PEPUtil.pEpClean()
            return true
        }
        return false
    }

    /**
     If pEp has been reinitialized, delete all folders and messsages.
     */
    func deleteAllFolders(pEpReInitialized: Bool) {
        if pEpReInitialized {
            // NSBatchDeleteRequest doesn't work so well here because of the need
            // to nullify the relations. This is used only for internal testing, so the
            // performance is neglible.
            let folders = CdFolder.all() as? [CdFolder] ?? []
            for f in folders {
                f.delete()
            }

            let msgs = CdMessage.all() as? [CdMessage] ?? []
            for m in msgs {
                m.delete()
            }

            CdHeaderField.deleteOrphans()
            Record.saveAndWait()
        }
    }
}

extension AppDelegate: BackgroundTaskProtocol {
    func beginBackgroundTask(taskName: String? = nil,
                             expirationHandler: (() -> Void)? = nil) -> BackgroundTaskID {
        var bgId = 0
        bgId = application.beginBackgroundTask(withName: taskName, expirationHandler: {
            expirationHandler?()
            self.application.endBackgroundTask(bgId)
        })
        return bgId
    }

    func endBackgroundTask(_ taskID: BackgroundTaskID?) {
        if let bID = taskID {
            application.endBackgroundTask(bID)
        }
    }
}

extension AppDelegate: KickOffMySelfProtocol {
    func startMySelf() {
        kickOffMySelf()
    }
}
