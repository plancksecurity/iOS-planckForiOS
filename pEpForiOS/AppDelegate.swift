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

    /** The SMTP/IMAP backend */
    var messageModelService: MessageModelService?

    /**
     Error Handler to connect backend with UI
     */
    var errorPropagator = ErrorPropagator()

    var application: UIApplication {
        return UIApplication.shared
    }

    let mySelfQueue = LimitedOperationQueue()

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

    private func setupInitialViewController() -> Bool {
        guard let appConfig = appConfig else {
            Logger.appDelegateLogger.errorAndCrash("No AppConfig")
            return false
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "FolderViews", bundle: nil)
        guard let initialNVC = mainStoryboard.instantiateViewController(withIdentifier: "main.initial.nvc") as? UISplitViewController,
            let navController = initialNVC.viewControllers.first as? UINavigationController,
            let rootVC = navController.rootViewController as? FolderTableViewController
            else {
                Logger.appDelegateLogger.errorAndCrash("Problem initializing UI")
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
        messageModelService?.start()
    }

    /// Signals all PEPSession users to stop using a session as soon as possible.
    /// NetworkService will assure all local changes triggered by the user are synced to the server
    /// and call it's delegate (me) after the last sync operation has finished.
    private func stopUsingPepSession() {
        syncUserActionsAndCleanupbackgroundTaskId =
            application.beginBackgroundTask(expirationHandler: { [unowned self] in
                Logger.appDelegateLogger.errorAndCrash(
                    "syncUserActionsAndCleanupbackgroundTask with ID %{public}@ expired",
                    self.syncUserActionsAndCleanupbackgroundTaskId)
                // We migh want to call some (yet unexisting) emergency shutdown on NetworkService here
                // that brutally shuts down everything.
                self.application.endBackgroundTask(self.syncUserActionsAndCleanupbackgroundTaskId)
            })
        messageModelService?.processAllUserActionsAndStop()
    }

    func cleanupPEPSessionIfNeeded() {
        if shouldDestroySession {
            PEPSession.cleanup()
        }
    }

    func kickOffMySelf() {
        mySelfTaskId = application.beginBackgroundTask(expirationHandler: { [unowned self] in
            Logger.appDelegateLogger.log(
                "mySelfTaskId with ID %{public}@ expired.",
                self.mySelfTaskId)
            // We migh want to call some (yet unexisting) emergency shutdown on NetworkService here
            // that brutally shuts down everything.
            self.application.endBackgroundTask(self.mySelfTaskId)
        })
        let op = MySelfOperation()
        op.completionBlock = { [unowned self] in
            // We might be the last service that finishes, so we have to cleanup.
            self.cleanupPEPSessionIfNeeded()
            if self.mySelfTaskId == UIBackgroundTaskInvalid {
                return
            }
            self.application.endBackgroundTask(self.mySelfTaskId)
            self.mySelfTaskId = UIBackgroundTaskInvalid
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
            Logger.appDelegateLogger.errorAndCrash("Error while Loading DataStack")
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
        let theAppConfig = AppConfig(
            mySelfer: self,
            errorPropagator: errorPropagator,
            oauth2AuthorizationFactory: oauth2Provider)
        appConfig = theAppConfig
        // This is a very dirty hack!! See SecureWebViewController docs for details.
        SecureWebViewController.appConfigDirtyHack = theAppConfig

        // set up logging for libraries

        // TODO: IOS-1276 set MessageModelConfig.logger

        loadCoreDataStack()
        messageModelService = MessageModelService()
        messageModelService?.delegate = self
    }

    // Safely restarts all services
    private func shutdownAndPrepareServicesForRestart() {
        // We cancel the Network Service to make sure it is idle and ready for a clean restart.
        // The actual restart of the services happens in NetworkServiceDelegate callbacks.
        messageModelService?.cancel()
    }

    private func prepareUserNotifications() {
        UserNotificationTool.resetApplicationIconBadgeNumber()
        UserNotificationTool.askForPermissions() { granted in
            // We do not care about whether or not the user granted permissions to
            // post notifications here (e.g. we ignore granted)
            // The calls are nested to avoid simultaniously showing permissions alert for notifications
            // and contact access.
            DispatchQueue.global(qos: .userInitiated).async {
                MessageModelUtil.perform {
                    AddressBook.checkAndTransfer()
                }
            }
        }
    }

    // MARK: - UIApplicationDelegate

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Logger.appDelegateLogger.log("applicationDidReceiveMemoryWarning")
    }

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }

        application.setMinimumBackgroundFetchInterval(60.0 * 10)

        Appearance.pEp()

        let pEpReInitialized = deleteManagementDBIfRequired()

        setupServices()
        Logger.appDelegateLogger.log("Library url: %{public}@", String(describing: applicationDirectory()))
        deleteAllFolders(pEpReInitialized: pEpReInitialized)

        prepareUserNotifications()

        let result = setupInitialViewController()

        return result
    }

    func applicationWillResignActive(_ application: UIApplication) {
        shutdownAndPrepareServicesForRestart()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        shouldDestroySession = true
        // generate keys in the background
        kickOffMySelf()
        stopUsingPepSession()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DispatchQueue.global(qos: .userInitiated).async {
            MessageModelUtil.perform {
                AddressBook.checkAndTransfer()
            }
        }
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
        
        guard let messageModelService = messageModelService else {
            Logger.appDelegateLogger.error("no networkService")
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

extension AppDelegate: MessageModelServiceDelegate {

    func messageModelServiceDidFinishLastSyncLoop() {
        // Cleanup sessions.
        PEPSession.cleanup()
        if syncUserActionsAndCleanupbackgroundTaskId == UIBackgroundTaskInvalid {
            return
        }
        if UIApplication.shared.applicationState != .background {
            // We got woken up again before syncUserActionsAndCleanupbackgroundTask finished.
            // No problem, start regular sync loop.
            startServices()
        }
        application.endBackgroundTask(syncUserActionsAndCleanupbackgroundTaskId)
        syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskInvalid
    }

    func messageModelServiceDidCancel() {
        switch UIApplication.shared.applicationState {
        case .background:
            // We have been cancelled because we are entering background.
            // Quickly sync local changes and clean up.
            stopUsingPepSession()
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
