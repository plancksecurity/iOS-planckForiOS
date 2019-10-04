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

    /// Tell the model that is is save to start services.
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
    private func gracefullyShutdownServices() { //BUFF: must go change
        guard syncUserActionsAndCleanupbackgroundTaskId == UIBackgroundTaskIdentifier.invalid
            else {
                Log.shared.error("Will not start background sync, pending %d",
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
        messageModelService?.processAllUserActionsAndStop() //BUFF: must go away
    }

    func cleanupPEPSessionIfNeeded() {
        if shouldDestroySession {
            PEPSession.cleanup()
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
        // For better  user acceptance we want to ask the user for contact access permissions in the
        // moment he uses a feature that requires access. Thus we do not touch CNContacts before
        // that happened.
        let shouldUpdateIdentities = AppSettings.userHasBeenAskedForContactAccessPermissions
        // We cancel the Network Service to make sure it is idle and ready for a clean restart.
        // The actual restart of the services happens in ReplicationServiceDelegate callbacks.
        messageModelService?.cancel(updateIdentities: shouldUpdateIdentities)
    }

    private func askUserForNotificationPermissions() {
        UserNotificationTool.resetApplicationIconBadgeNumber()
        UserNotificationTool.askForPermissions()
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

        setupServices()

        askUserForNotificationPermissions()

        let result = setupInitialViewController()

        return result
    }

    /// Sent when the application is about to move from active to inactive state. This can occur
    /// for certain types of temporary interruptions (such as an incoming phone call or SMS message)
    /// or when the user quits the application and it begins the transition to the background state.
    /// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame
    /// rates. Games should use this method to pause the game.
    func applicationWillResignActive(_ application: UIApplication) {
        shutdownAndPrepareServicesForRestart() //BUFF: this is even called when showing an alert !
    }

    /// Use this method to release shared resources, save user data, invalidate timers, and store
    /// enough application state information to restore your application to its current state in
    /// case it is terminated later.
    /// If your application supports background execution, this method is called instead of
    /// applicationWillTerminate: when the user quits.
    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.shared.info("applicationDidEnterBackground")
        shouldDestroySession = true
        gracefullyShutdownServices()
    }

    /// Called as part of the transition from the background to the inactive state; here you can
    /// undo many of the changes made on entering the background.
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Desparate try to wokaround lagging PEPSessionProvider issue (IOS-1769)
        // The suspect is that PEPSessionProvider has problems when the first call for a PEPSession is done from a non-main thread.
        let _ = PEPSession()
    }

    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    /// If the application was previously in the background, optionally refresh the user interface.
    /// Note: this is also called when:
    /// - swiping down the iOS system notification center
    /// - iOS auto lock takes place
    func applicationDidBecomeActive(_ application: UIApplication) {
        if MiscUtil.isUnitTest() {
            // Do nothing if unit tests are running
            return
        }

        shouldDestroySession = false

        shutdownAndPrepareServicesForRestart()
        UserNotificationTool.resetApplicationIconBadgeNumber()
    }

    /// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    /// Saves changes in the application's managed object context before the application terminates.
    func applicationWillTerminate(_ application: UIApplication) {
        shouldDestroySession = true
        // Just in case, last chance to clean up. Should not be necessary though.
        cleanupPEPSessionIfNeeded()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let messageModelService = messageModelService else {
            Log.shared.error("no networkService")
            return
        }
        
        messageModelService.checkForNewMails() {[unowned self] (numMails: Int?) in
            guard let numMails = numMails else {
                self.cleanup(andCall: completionHandler, result: .failed)
                return
            }
            switch numMails {
            case 0:
                self.cleanup(andCall: completionHandler, result: .noData)
            default:
                self.informUser(numNewMails: numMails) {
                    self.cleanup(andCall: completionHandler, result: .newData)
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

    private func cleanup(andCall completionHandler:(UIBackgroundFetchResult) -> Void,
                                result:UIBackgroundFetchResult) {
        PEPSession.cleanup()
        completionHandler(result)
    }
}

// MARK: - ReplicationServiceDelegate

extension AppDelegate: MessageModelServiceDelegate {

    func messageModelServiceDidFinishLastSyncLoop() { //BUFF: must go away
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

    func messageModelServiceDidCancel() { //BUFF: must go away
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
        @unknown default:
            Log.shared.errorAndCrash("Apple, please folow your own advice and use CLOSED_ENUM in Obj-C")
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
