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
     Error Handler to connect backend with UI
     */
    var errorPropagator = ErrorPropagator()

    var application: UIApplication {
        return UIApplication.shared
    }

    let mySelfQueue = LimitedOperationQueue()

    lazy var appSettings = AppSettings()

    let sendLayerDelegate = DefaultUISendLayerDelegate()

    /**
     This is used to handle OAuth2 requests.
     */
    let oauth2Provider = OAuth2ProviderFactory().oauth2Provider()

    var syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskInvalid
    var mySelfTaskId = UIBackgroundTaskInvalid

    /**
     Set to true whever the app goes into background, so the main session gets cleaned up.
     */
    var shouldDestroySession = false

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

    private func setupInitialViewController() -> Bool {
        guard let appConfig = appConfig else {
            Log.shared.errorAndCrash(component: #function, errorString: "No AppConfig")
            return false
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "FolderViews", bundle: nil)
        guard let initialNVC = mainStoryboard.instantiateViewController(withIdentifier: "main.initial.nvc") as? UISplitViewController,
            let navController = initialNVC.viewControllers.first as? UINavigationController,
            let rootVC = navController.rootViewController as? FolderTableViewController
            else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Problem initializing UI")
                return false
        }
        rootVC.appConfig = appConfig
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = initialNVC
        window.makeKeyAndVisible()

        return true
    }

    /// Signals al services to start/resume.
    /// Also signals it is save to use PEPSessions (again)
    private func startServices() {
        Log.shared.resume()
        networkService?.start()
    }

    /// Signals all PEPSession users to stop using a session as soon as possible.
    /// NetworkService will assure all local changes triggered by the user are synced to the server
    /// and call it's delegate (me) after the last sync operation has finished.
    private func stopUsingPepSession() {
        syncUserActionsAndCleanupbackgroundTaskId =
            application.beginBackgroundTask(expirationHandler: { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                    return
                }
                Log.shared.warn(component: #function,
                                content: "syncUserActionsAndCleanupbackgroundTask with ID " +
                    "\(me.syncUserActionsAndCleanupbackgroundTaskId) expired.")
                // We migh want to call some (yet unexisting) emergency shutdown on NetworkService here
                // that brutally shuts down everything.
                me.application.endBackgroundTask(me.syncUserActionsAndCleanupbackgroundTaskId)
            })
        networkService?.processAllUserActionsAndstop()
        // Stop logging to Engine. It would create new sessions.
        Log.shared.pause()
    }

    func cleanupPEPSessionIfNeeded() {
        if shouldDestroySession {
            PEPSession.cleanup()
        }
    }

    func kickOffMySelf() {
        mySelfTaskId = application.beginBackgroundTask(expirationHandler: { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            Log.shared.warn(component: #function,
                            content: "mySelfTaskId with ID \(me.mySelfTaskId) expired.")
            // We migh want to call some (yet unexisting) emergency shutdown on NetworkService here
            // that brutally shuts down everything.
            me.application.endBackgroundTask(me.mySelfTaskId)
        })
        let op = MySelfOperation()
        op.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            // We might be the last service that finishes, so we have to cleanup.
            self?.cleanupPEPSessionIfNeeded()
            if me.mySelfTaskId == UIBackgroundTaskInvalid {
                return
            }
            me.application.endBackgroundTask(me.mySelfTaskId)
            me.mySelfTaskId = UIBackgroundTaskInvalid

        }
        mySelfQueue.addOperation(op)
    }

    func loadCoreDataStack() {
        let objectModel = MessageModelData.MessageModelData()
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true]
        do {
            try Record.loadCoreDataStack(managedObjectModel: objectModel,
                                         storeURL: nil,
                                         options: options)
        } catch {
            Log.shared.errorAndCrash(component: comp, errorString: "Error while Loading DataStack")
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

    private func setupServices() {
        // Needs to be done once to set defaults. Calling it more than once does not do any harm.
        let _ = AppSettings()

        let theMessageSyncService = MessageSyncService()
        let keyImportService = KeyImportService()
        let theAppConfig = AppConfig(mySelfer: self,
                                     messageSyncService: theMessageSyncService,
                                     errorPropagator: errorPropagator,
                              		 keyImportService: keyImportService,
                                     oauth2AuthorizationFactory: oauth2Provider)
        appConfig = theAppConfig
        // This is a very dirty hack!! See SecureWebViewController docs for details.
        SecureWebViewController.appConfigDirtyHack = theAppConfig

        // set up logging for libraries
        MessageModelConfig.logger = Log.shared

        loadCoreDataStack()

        networkService = NetworkService(mySelfer: self,
                                        errorPropagator: errorPropagator,
                                        keyImportListener: keyImportService)
        networkService?.sendLayerDelegate = sendLayerDelegate
        networkService?.delegate = self
        // MessageModel must not know about the send layer.
        // Is used for unit test only. Maybe refactor out.
        CdAccount.sendLayer = networkService
    }

    private func prepareUserNotifications() {
        UserNotificationTool.resetApplicationIconBadgeNumber()
        UserNotificationTool.askForPermissions() { granted in
            // We do not care about whether or not the user granted permissions to
            // post notifications here (e.g. we ignore granted)
            // The calls are nested to avoid simultaniously showing permissions alert for notifications
            // and contact access.
            DispatchQueue.global(qos: .userInitiated).async {
                MessageModel.perform {
                    AddressBook.checkAndTransfer()
                }
            }
        }
    }

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FolderThreading.switchThreading(onOrOff: appSettings.threadedViewEnabled)

        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }
        application.setMinimumBackgroundFetchInterval(60.0 * 10)

        Appearance.pEp()

        let pEpReInitialized = deleteManagementDBIfRequired()

        setupServices()
        Log.info(component: comp,
                 content: "Library url: \(String(describing: applicationDirectory()))")
        deleteAllFolders(pEpReInitialized: pEpReInitialized)

        prepareUserNotifications()

        let result = setupInitialViewController()

        return result
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.info(component: comp, content: "applicationDidEnterBackground")
        shouldDestroySession = true
        // generate keys in the background
        kickOffMySelf()
        stopUsingPepSession()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DispatchQueue.global(qos: .userInitiated).async {
            MessageModel.perform {
                AddressBook.checkAndTransfer()
            }
        }
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if MiscUtil.isUnitTest() {
            // Do nothing if unit tests are running
            return
        }

        shouldDestroySession = false

        startServices()
        kickOffMySelf()
        UserNotificationTool.resetApplicationIconBadgeNumber()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        shouldDestroySession = true

        // Just in case, last chance to clean up. Should not be necessary though.
        PEPSession.cleanup()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let networkService = networkService else {
            Log.shared.error(component: #function, errorString: "no networkService")
            return
        }
        
        networkService.checkForNewMails() { (numMails: Int?) in
            guard let numMails = numMails else {
                self.cleanupAndCall(completionHandler: completionHandler, result: .failed)
                return
            }
            switch numMails {
            case 0:
                self.cleanupAndCall(completionHandler: completionHandler, result: .noData)
            default:
                self.informUser(numNewMails: numMails) {
                    self.cleanupAndCall(completionHandler: completionHandler, result: .newData)
                }
            }
        }
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Unclear if this is needed, presumabley doesn't get invoked for OAuth2 because
        // SFSafariViewController is involved there.
        return oauth2Provider.processAuthorizationRedirect(url: url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let theUrl = userActivity.webpageURL {
            return oauth2Provider.processAuthorizationRedirect(url: theUrl)
        }
        return false
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Log.shared.warn(component: "UIApplicationDelegate",
                        content: "applicationDidReceiveMemoryWarning")
    }

    // MARK: - HELPER

    private func cleanupAndCall(completionHandler:(UIBackgroundFetchResult) -> Void,
                                result:UIBackgroundFetchResult) {
        PEPSession.cleanup()
        completionHandler(result)
    }
}

// MARK: - KickOffMySelfProtocol

extension AppDelegate: KickOffMySelfProtocol {
    func startMySelf() {
        kickOffMySelf()
    }
}

// MARK: - NetworkServiceDelegate

extension AppDelegate: NetworkServiceDelegate {
    func networkServiceDidFinishLastSyncLoop(service: NetworkService) {
        // Cleanup sessions.
        Log.shared.infoComponent(#function, message: "Clean up sessions.")
        PEPSession.cleanup()
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            if me.syncUserActionsAndCleanupbackgroundTaskId == UIBackgroundTaskInvalid {
                return
            }
            me.application.endBackgroundTask(me.syncUserActionsAndCleanupbackgroundTaskId)
            me.syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskInvalid
        }
    }
}

// MARK: - User Notifiation

extension AppDelegate {
    private func informUser(numNewMails:Int, completion: @escaping ()->()) {
        GCD.onMain {
            UserNotificationTool.postUserNotification(forNumNewMails: numNewMails)
            completion()
        }
    }
}
