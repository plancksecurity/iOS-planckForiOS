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

    var syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskIdentifier.invalid
    var mySelfTaskId = UIBackgroundTaskIdentifier.invalid

    /**
     Set to true whever the app goes into background, so the main session gets cleaned up.
     */
    var shouldDestroySession = false

    let notifyHandshakeDelegate: PEPNotifyHandshakeDelegate = NotifyHandshakeDelegate()

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
        messageModelService?.start()
    }

    /// Signals all PEPSession users to stop using a session as soon as possible.
    /// ReplicationService will assure all local changes triggered by the user are synced to the server
    /// and call it's delegate (me) after the last sync operation has finished.
    private func stopUsingPepSession() {
        syncUserActionsAndCleanupbackgroundTaskId =
            application.beginBackgroundTask(expirationHandler: { [unowned self] in
                Log.shared.errorAndCrash(
                    "syncUserActionsAndCleanupbackgroundTask with ID %{public}@ expired",
                    self.syncUserActionsAndCleanupbackgroundTaskId as CVarArg)
                // We migh want to call some (yet unexisting) emergency shutdown on
                // ReplicationService here that brutally shuts down everything.
                self.application.endBackgroundTask(UIBackgroundTaskIdentifier(
                    rawValue: self.syncUserActionsAndCleanupbackgroundTaskId.rawValue))
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
            Log.shared.log("mySelfTaskId with ID expired.")
            // We migh want to call some (yet unexisting) emergency shutdown on
            // ReplicationService here here that brutally shuts down everything.
            self.application.endBackgroundTask(
                UIBackgroundTaskIdentifier(rawValue:self.mySelfTaskId.rawValue))
        })
        let op = MySelfOperation()
        op.completionBlock = { [unowned self] in
            // We might be the last service that finishes, so we have to cleanup.
            self.cleanupPEPSessionIfNeeded()
            if self.mySelfTaskId == UIBackgroundTaskIdentifier.invalid {
                return
            }
            self.application.endBackgroundTask(
                UIBackgroundTaskIdentifier(rawValue: self.mySelfTaskId.rawValue))
            self.mySelfTaskId = UIBackgroundTaskIdentifier.invalid
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
            Log.shared.errorAndCrash("Error while Loading DataStack")
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
        messageModelService = MessageModelService(
            mySelfer: self,
            errorPropagator: errorPropagator,
            notifyHandShakeDelegate: notifyHandshakeDelegate)
        messageModelService?.delegate = self
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
        Log.shared.log("applicationDidReceiveMemoryWarning")
    }

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }

        application.setMinimumBackgroundFetchInterval(60.0 * 10)

        Appearance.pEp()

        let pEpReInitialized = deleteManagementDBIfRequired()

        setupServices()
        Log.shared.log("Library url: %{public}@", String(describing: applicationDirectory()))
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

    func applicationDidEnterBackground(_ application: UIApplication) {
        shouldDestroySession = true
        // generate keys in the background
        kickOffMySelf()
        stopUsingPepSession()
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

        guard !Account.all().isEmpty else { //No account, no logged in, ignore and log in then
            Log.shared.log("User try to share something, but was not logged in")
            return false
        }
        guard let appConfig = appConfig else {
            Log.shared.errorAndCrash("%@", AppError.General.noAppConfig.localizedDescription)
            return false
        }

        guard let navigtion = window?.rootViewController as? UINavigationController,
              let composeViewController =
                       ComposeTableViewController.instantiate(fromAppStoryboard: .main) else {
            Log.shared.errorAndCrash("%@",
                            AppError.Storyboard.failToInitViewController.localizedDescription)
            return false
        }
        composeViewController.appConfig = appConfig
        composeViewController.viewModel = ComposeViewModel(resultDelegate: nil,
                composeMode: .normal, prefilledTo: nil, prefilledFrom: nil, originalMessage: nil)
        navigtion.pushViewController(composeViewController, animated: true)
        return true
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

// MARK: - KickOffMySelfProtocol

extension AppDelegate: KickOffMySelfProtocol {
    func startMySelf() {
        kickOffMySelf()
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
        application.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: syncUserActionsAndCleanupbackgroundTaskId.rawValue))
        syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskIdentifier.invalid
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
