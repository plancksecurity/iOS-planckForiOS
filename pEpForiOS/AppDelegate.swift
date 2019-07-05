//
//  AppDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import MessageModel
import PEPObjCAdapterFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    var appConfig: AppConfig?

    /** The model */
    var messageModelService: MessageModelServiceProtocol?

    var deviceGroupService: KeySyncDeviceGroupService?

    /// Error Handler bubble errors up to the UI
    var errorPropagator = ErrorPropagator()

    let mySelfQueue = LimitedOperationQueue()

    /// This is used to handle OAuth2 requests.
    let oauth2Provider = OAuth2ProviderFactory().oauth2Provider()

    var syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskIdentifier.invalid

    /// Set to true whever the app goes into background, so the main PEPSession gets cleaned up.
    var shouldDestroySession = false

    func applicationDirectory() -> URL? {
        let fm = FileManager.default
        let dirs = fm.urls(for: .libraryDirectory, in: .userDomainMask)
        return dirs.first
    }

    private func setupInitialViewController() -> Bool {
        guard let appConfig = appConfig else {
            Log.shared.errorAndCrash("No AppConfig")
            return false
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "FolderViews", bundle: nil)
        guard let initialNVC = mainStoryboard.instantiateViewController(withIdentifier: "main.initial.nvc") as? UISplitViewController,
            let navController = initialNVC.viewControllers.first as? UINavigationController,
            let rootVC = navController.rootViewController as? FolderTableViewController
            else {
                Log.shared.errorAndCrash("Problem initializing UI")
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
        do {
            try messageModelService?.start()
        } catch {
            Log.shared.log(error: error)
        }
    }

    /// Signals all PEPSession users to stop using a session as soon as possible.
    /// ReplicationService will assure all local changes triggered by the user are synced to the server
    /// and call it's delegate (me) after the last sync operation has finished.
    private func gracefullyShutdownServices() {
        guard syncUserActionsAndCleanupbackgroundTaskId == UIBackgroundTaskIdentifier.invalid
            else {
                Log.shared.warn(
                    "Will not start background sync, pending %d",
                    syncUserActionsAndCleanupbackgroundTaskId.rawValue)
                return
        }
        syncUserActionsAndCleanupbackgroundTaskId =
            UIApplication.shared.beginBackgroundTask(expirationHandler: { [unowned self] in
                Log.shared.warn(
                    "syncUserActionsAndCleanupbackgroundTask with ID %d expired",
                    self.syncUserActionsAndCleanupbackgroundTaskId.rawValue)
                // We migh want to call some (yet unexisting) emergency shutdown on
                // ReplicationService here that brutally shuts down everything.
                UIApplication.shared.endBackgroundTask(self.syncUserActionsAndCleanupbackgroundTaskId)
                self.syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskIdentifier.invalid

                Log.shared.errorAndCrash(
                    "syncUserActionsAndCleanupbackgroundTask with ID %d expired",
                    self.syncUserActionsAndCleanupbackgroundTaskId.rawValue)
            })
        messageModelService?.processAllUserActionsAndStop()
    }

    func cleanupPEPSessionIfNeeded() {
        if shouldDestroySession {
            PEPSession.cleanup()
        }
    }

    /**
     Removes all keys, and the management DB, when the user chooses so.
     - Returns: True if the pEp management DB was deleted, so further actions can be taken.
     */
    func deleteManagementDBIfRequired() -> Bool {
        if AppSettings.shouldReinitializePepOnNextStartup {
            AppSettings.shouldReinitializePepOnNextStartup = false
            let _ = PEPUtil.pEpClean()
            return true
        }
        return false
    }

    //!!!: uses CD. Must go away (rm? else to MM)
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
        let keySyncHandshakeService = KeySyncHandshakeService()
        let deviceGroupService = KeySyncDeviceGroupService()
        self.deviceGroupService = deviceGroupService
        let theMessageModelService = MessageModelService(errorPropagator: errorPropagator,
                                                         keySyncServiceDelegate: keySyncHandshakeService,
                                                         deviceGroupDelegate: deviceGroupService,
                                                         keySyncEnabled: AppSettings.keySyncEnabled)
        theMessageModelService.delegate = self
        messageModelService = theMessageModelService

        appConfig = AppConfig(errorPropagator: errorPropagator,
                              oauth2AuthorizationFactory: oauth2Provider,
                              keySyncHandshakeService: keySyncHandshakeService,
                              messageModelService: theMessageModelService)

        // This is a very dirty hack!! See SecureWebViewController docs for details.
        SecureWebViewController.appConfigDirtyHack = appConfig
    }

    // Safely restarts all services
    private func shutdownAndPrepareServicesForRestart() {
        // We cancel the Network Service to make sure it is idle and ready for a clean restart.
        // The actual restart of the services happens in ReplicationServiceDelegate callbacks.
        messageModelService?.cancel()
    }

    private func askUserForPermissions() {
        UserNotificationTool.resetApplicationIconBadgeNumber()
        UserNotificationTool.askForPermissions() { [weak self] _ in
            // We do not care about whether or not the user granted permissions to
            // post notifications here (e.g. we ignore granted)
            // The calls are nested to avoid simultaniously showing permissions alert for notifications
            // and contact access.
            self?.askForContactAccessPermissionsAndImportContacts()
        }
    }

    private func askForContactAccessPermissionsAndImportContacts() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if AddressBook.shared.isAuthorized() {
                DispatchQueue.main.async {
                    self?.importContacts()
                }
            }
        }
    }

    private func importContacts() {
        DispatchQueue.global(qos: .background).async { //!!!: Must become background task. Or stoped when going to background imo.
            AddressBook.shared.transferContacts()
        }
    }

    // MARK: - UIApplicationDelegate

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Log.shared.warn("applicationDidReceiveMemoryWarning")
    }

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Log.shared.info("Library url: %@", String(describing: applicationDirectory()))

        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }

        application.setMinimumBackgroundFetchInterval(60.0 * 10)

        Appearance.pEp()

        let pEpReInitialized = deleteManagementDBIfRequired()

        setupServices()

        deleteAllFolders(pEpReInitialized: pEpReInitialized)

        askUserForPermissions()

        let result = setupInitialViewController()

        return result
    }

    func applicationWillResignActive(_ application: UIApplication) {
        shutdownAndPrepareServicesForRestart()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationWillEnterBackground(_ application: UIApplication) {
        Log.shared.warn("applicationWillEnterBackground")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.shared.warn("applicationDidEnterBackground")
        shouldDestroySession = true
        gracefullyShutdownServices()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        importContacts()
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    // Note: this is also called when:
    // - swiping down the iOS system notification center
    // - iOS auto lock takes place
    func applicationDidBecomeActive(_ application: UIApplication) {
        if MiscUtil.isUnitTest() {
            // Do nothing if unit tests are running
            return
        }

        shouldDestroySession = false

        shutdownAndPrepareServicesForRestart()
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
        
        guard let messageModelService = messageModelService else {
            Log.shared.error("no networkService")
            return
        }
        
        messageModelService.checkForNewMails() {[unowned self] (numMails: Int?) in
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
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Unclear if this is needed, presumabley doesn't get invoked for OAuth2 because
        // SFSafariViewController is involved there.
        return oauth2Provider.processAuthorizationRedirect(url: url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let theUrl = userActivity.webpageURL {
            return oauth2Provider.processAuthorizationRedirect(url: theUrl)
        }
        return false
    }

    // MARK: - HELPER

    private func cleanupAndCall(completionHandler:(UIBackgroundFetchResult) -> Void,
                                result:UIBackgroundFetchResult) {
        PEPSession.cleanup()
        completionHandler(result)
    }
}

// MARK: - ReplicationServiceDelegate

extension AppDelegate: MessageModelServiceDelegate {

    func messageModelServiceDidFinishLastSyncLoop() {
        // Cleanup sessions.
        PEPSession.cleanup()
        if syncUserActionsAndCleanupbackgroundTaskId == UIBackgroundTaskIdentifier.invalid {
            return
        }
        if UIApplication.shared.applicationState != .background {
            // We got woken up again before syncUserActionsAndCleanupbackgroundTask finished.
            // No problem, start regular sync loop.
            startServices()
        }
        UIApplication.shared.endBackgroundTask(syncUserActionsAndCleanupbackgroundTaskId)
        syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskIdentifier.invalid
    }

    func messageModelServiceDidCancel() {
        switch UIApplication.shared.applicationState {
        case .background:
            // We have been cancelled because we are entering background.
            // Quickly sync local changes and clean up.
            gracefullyShutdownServices()
        case .inactive:
            // We re inactive. Keep services paused -> Do nothing
            break
        case .active:
            // We have been cancelled soley to assure a clean restart.
            startServices()
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
