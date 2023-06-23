//
//  AppDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import BackgroundTasks

import PlanckToolbox
import MessageModel
import pEp4iosIntern

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var reachabilityManager : ReachabilityManager?

    /// The model
    private var messageModelService: MessageModelServiceProtocol?

    private let errorSubscriber = ErrorSubscriber()

    private let encryptionErrorHandler = EncryptionErrorHandler()

    /// AppSettingsObserver must be always alive to observe changes.
    /// The observer must be started by calling `start`
    private var appSettingsObserver: AppSettingsObserver = AppSettingsObserver.shared

    /// Error Handler bubble errors up to the UI
    private lazy var errorPropagator: ErrorPropagator = {
        let createe = ErrorPropagator(subscriber: errorSubscriber)
        return createe
    }()

    private let userInputProvider = UserInputProvider()

    /// This is used to handle OAuth2 requests.
    private let oauth2Provider = OAuth2ProviderFactory().oauth2Provider()

    private func setupInitialViewController() -> Bool {
        let folderViews: UIStoryboard = UIStoryboard(name: "FolderViews", bundle: nil)
        guard let initialNVC = folderViews.instantiateViewController(withIdentifier: "main.initial.nvc") as? UISplitViewController
            else {
                Log.shared.errorAndCrash("Problem initializing UI")
                return false
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = initialNVC
        window.makeKeyAndVisible()

        return true
    }

    private func setupServices() {
        if !MDMUtil.isEnabled() {
            EchoProtocolUtil().enableEchoProtocol(enabled: true)
        }

        messageModelService = MessageModelService(errorPropagator: errorPropagator,
                                                  cnContactsAccessPermissionProvider: AppSettings.shared,
                                                  keySyncServiceHandshakeHandler: KeySyncHandshakeService(),
                                                  keySyncStateProvider: AppSettings.shared,
                                                  usePlanckFolderProvider: AppSettings.shared,
                                                  passphraseProvider: userInputProvider,
                                                  encryptionErrorDelegate: encryptionErrorHandler,
                                                  outgoingRatingService: OutgoingRatingChangeService(),
                                                  auditLoggingProtocol: AuditLoggingService.shared)
    }

    /// Start observing the appSettings
    private func startAppSettingsObserver() {
        appSettingsObserver.start()
    }

    private func askUserForNotificationPermissions() {
        UserNotificationTool.resetApplicationIconBadgeNumber()
        UserNotificationTool.askForPermissions()
    }
}

// MARK: - UIApplicationDelegate

extension AppDelegate {

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Log.shared.warn("applicationDidReceiveMemoryWarning")
        IdentityImageTool.clearCache()
        messageModelService?.freeMemory()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }
        Log.shared.verboseLoggingEnabled = AppSettings.shared.verboseLogginEnabled

        Log.shared.logDebugInfo()

        Log.shared.info("BGAppRefreshTask: Registering BGTaskScheduler.shared.register(forTaskWithIdentifier: ...")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.appRefreshTaskBackgroundtaskBackgroundfetchSchedulerid,
                                        using: nil) { [weak self] task in
            guard let me = self else {
                Log.shared.errorAndCrash("BGAppRefreshTask: Lost myself")
                return
            }
            me.handleAppRefreshTask(task as! BGAppRefreshTask)
        }

        Appearance.setup()
        setupServices()
        startAppSettingsObserver()
        askUserForNotificationPermissions()
        var result = setupInitialViewController()
        if let openedToOpenFile = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            // We have been opened by the OS to handle a certain file.
            result = handleUrlTheOSHasBroughtUsToForgroundFor(openedToOpenFile)
        }
        self.reachabilityManager = ReachabilityManager.shared
        return result
    }

    /// Sent when the application is about to move from active to inactive state. This can occur
    /// for certain types of temporary interruptions (such as an incoming phone call or SMS message)
    /// or when the user quits the application and it begins the transition to the background state.
    /// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame
    /// rates. Games should use this method to pause the game.
    ///
    /// - note: this is also called when:
    ///         * an alert is shown (e.g. OS asks for CNContact access permissions)
    ///         * the user swipes up/down the "ControllCenter"
    ///         * the keyboard is shown the first time on iOS13 and the "you can now swipe instead
    ///             of typing" view is shown
    func applicationWillResignActive(_ application: UIApplication) {
        // We intentionally do nothing here.
        // We assume to be kept alive until being informed (by another delegate method) otherwize.
    }

    /// Use this method to release shared resources, save user data, invalidate timers, and store
    /// enough application state information to restore your application to its current state in
    /// case it is terminated later.
    /// If your application supports background execution, this method is called instead of
    /// applicationWillTerminate: when the user quits.
    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.shared.info("applicationDidEnterBackground")
        Session.main.commit()
        messageModelService?.finish()
        // Make sure we do not permanently disable auto locking
        UIApplication.shared.enableAutoLockingDevice()
        scheduleAppRefresh()
        AuditLoggingUtil.shared.logEvent(maxLogTime: AppSettings.shared.auditLoggingTime, auditLoggerEvent: .stop)
    }

    /// Called as part of the transition from the background to the inactive state; here you can
    /// undo many of the changes made on entering the background.
    func applicationWillEnterForeground(_ application: UIApplication) {
        AuditLoggingUtil.shared.logEvent(maxLogTime: AppSettings.shared.auditLoggingTime, auditLoggerEvent: .start)
    }

    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    /// If the application was previously in the background, optionally refresh the user interface.
    /// - Note: this is also called when:
    /// - swiping down the iOS system notification center
    /// - iOS auto lock takes place
    func applicationDidBecomeActive(_ application: UIApplication) {
        if MiscUtil.isUnitTest() {
            // Do nothing if unit tests are running
            return
        }
        UserNotificationTool.resetApplicationIconBadgeNumber()
        messageModelService?.start()
    }

    /// Called when the application is about to terminate. Save data if appropriate. See also
    /// applicationDidEnterBackground:.
    /// Saves changes in the application's managed object context before the application terminates.
    func applicationWillTerminate(_ application: UIApplication) {
        AuditLoggingUtil.shared.logEvent(maxLogTime: AppSettings.shared.auditLoggingTime, auditLoggerEvent: .stop)
        messageModelService?.stop()
        // Make sure we do not permanently disable auto locking
        UIApplication.shared.enableAutoLockingDevice()
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler
                     completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // According to Apple docs:
        //
        // "Adding a BGTaskSchedulerPermittedIdentifiers key to the
        // Info.plist disables application(_:performFetchWithCompletionHandler:) and
        // setMinimumBackgroundFetchInterval(_:) in iOS 13 and later."
        //
        // This method is called anyway by the OS. Which is a contradiction imo.
        //
        // Do a background fetch anyways, because, why not?
        guard let messageModelService = messageModelService else {
            Log.shared.error("no networkService")
            completionHandler(.failed)
            return
        }

        messageModelService.checkForNewMails_old() {[unowned self] (numMails: Int?) in
            var result = UIBackgroundFetchResult.failed
            defer { completionHandler(result)}
            guard let numMails = numMails else {
                result = .failed
                return
            }
            switch numMails {
            case 0:
                result = .noData
            default:
                self.informUser(numNewMails: numMails) {
                    result = .newData
                }
            }
        }
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleUrlTheOSHasBroughtUsToForgroundFor(url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let theUrl = userActivity.webpageURL {
            return oauth2Provider.processAuthorizationRedirect(url: theUrl)
        }
        return false
    }
}

// MARK: - BGAppRefreshTask

extension AppDelegate {

    private func handleAppRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule a new refresh task
        scheduleAppRefresh()

        guard let messageModelService = messageModelService else {
            Log.shared.error("BGAppRefreshTask: no networkService")
            task.setTaskCompleted(success: false)
            return
        }

        task.expirationHandler = {
            messageModelService.cancelCheckForNewMails_old()
        }

        Log.shared.info("BGAppRefreshTask: Start checking for new mails")
        messageModelService.checkForNewMails_old() { [unowned self] (numMails: Int?) in
            var success = false
            defer { task.setTaskCompleted(success: success) }
            guard let numMails = numMails else {
                Log.shared.error("BGAppRefreshTask: checkForNewMails returned nil")
                success = false
                return
            }
            switch numMails {
            case 0:
                Log.shared.info("BGAppRefreshTask: Server reported zero new mails")
                success = true
            default:
                self.informUser(numNewMails: numMails) {
                    Log.shared.info("BGAppRefreshTask: Server reported %d new mails", numMails)
                    success = true
                }
            }
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.appRefreshTaskBackgroundtaskBackgroundfetchSchedulerid)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60.0 * 2)
        do {
            Log.shared.info("BGAppRefreshTask: scheduleAppRefresh() called")
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Log.shared.warn("BGAppRefreshTask: Could not schedule app refresh: %@. If error is \"1\" (BGTaskScheduler.Error.unavailable), possible causes are: \n- You are on simulater (background fetch not supported any more)\n- The user has disabled background refresh in settings\n- The extension either hasn’t set RequestsOpenAccess to YES in The Info.plist File, or the user hasn’t granted open access", error.localizedDescription)
        }
    }
}

// MARK: - User Notification

extension AppDelegate {
    private func informUser(numNewMails:Int, completion: @escaping ()->()) {
        DispatchQueue.main.async {
            UserNotificationTool.postUserNotification(forNumNewMails: numNewMails)
            completion()
        }
    }
}

// MARK: - Client Certificate Import

extension AppDelegate {

    @discardableResult
    private func handleUrlTheOSHasBroughtUsToForgroundFor(_ url: URL) -> Bool {
        if url.isMailto {
            guard let mailto = Mailto(url: url) else {
                Log.shared.errorAndCrash("Mailto parsing failed")
                return false
            }
            UIUtils.showComposeView(from: mailto)
            return true
        }
        switch url.pathExtension {
        case ClientCertificateImportViewController.pEpClientCertificateExtension:
            return handleClientCertificateImport(forCertAt: url)
        default:
            Log.shared.errorAndCrash("Unexpected call. open for file with extention: %@",
                                     url.pathExtension)
        }
        return false
    }

    private func handleClientCertificateImport(forCertAt url: URL) -> Bool {
        guard url.pathExtension == ClientCertificateImportViewController.pEpClientCertificateExtension else {
            Log.shared.errorAndCrash("This method is only for .pEp12 files.")
            return false
        }
        let topVC = UIApplication.currentlyVisibleViewController()
        guard let vc = UIStoryboard.init(name: Constants.certificatesStoryboard, bundle: nil).instantiateViewController(withIdentifier: ClientCertificateImportViewController.storyboadIdentifier) as? ClientCertificateImportViewController else {
            return false
        }
        vc.viewModel = ClientCertificateImportViewModel(certificateUrl: url, delegate: vc)
        if let topDelegate = topVC as? ClientCertificateImportViewControllerDelegate {
            vc.delegate = topDelegate
        }
        vc.modalPresentationStyle = .fullScreen
        topVC.present(vc, animated: true)
        return true
    }
}
