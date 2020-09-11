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

    /** The model */
    private var messageModelService: MessageModelServiceProtocol?

    private var errorSubscriber = ErrorSubscriber()
    
    /// Error Handler bubble errors up to the UI
    private lazy var errorPropagator: ErrorPropagator = {
        let createe = ErrorPropagator(subscriber: errorSubscriber)
        return createe
    }()

    private let userInputProvider = UserInputProvider()

    /// This is used to handle OAuth2 requests.
    private let oauth2Provider = OAuth2ProviderFactory().oauth2Provider()

    private var syncUserActionsAndCleanupbackgroundTaskId = UIBackgroundTaskIdentifier.invalid

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
        messageModelService = MessageModelService(errorPropagator: errorPropagator,
                                                  cnContactsAccessPermissionProvider: AppSettings.shared,
                                                  keySyncServiceHandshakeHandler: KeySyncHandshakeService(),
                                                  keySyncStateProvider: AppSettings.shared,
                                                  usePEPFolderProvider: AppSettings.shared,
                                                  passphraseProvider: userInputProvider)
    }

    private func askUserForNotificationPermissions() {
        UserNotificationTool.resetApplicationIconBadgeNumber()
        UserNotificationTool.askForPermissions()
    }

    // MARK: - HELPER

    private func cleanup(andCall completionHandler:(UIBackgroundFetchResult) -> Void,
                         result:UIBackgroundFetchResult) {
        PEPSession.cleanup()
        completionHandler(result)
    }
}

// MARK: - UIApplicationDelegate

extension AppDelegate {

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        //Log.shared.errorAndCrash("applicationDidReceiveMemoryWarning")
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if MiscUtil.isUnitTest() {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }
        Log.shared.logDebugInfo()

        application.setMinimumBackgroundFetchInterval(60.0 * 10)
        Appearance.setup()
        setupServices()
        askUserForNotificationPermissions()
        var result = setupInitialViewController()

        if let openedToOpenFile = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            // We have been opened by the OS to handle a certain file.
            result = handleUrlTheOSHasBroughtUsToForgroundFor(openedToOpenFile)
        }

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
    }

    /// Called as part of the transition from the background to the inactive state; here you can
    /// undo many of the changes made on entering the background.
    func applicationWillEnterForeground(_ application: UIApplication) {
        // do nothing (?)
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
        UserNotificationTool.resetApplicationIconBadgeNumber()
        messageModelService?.start()
    }

    /// Called when the application is about to terminate. Save data if appropriate. See also
    /// applicationDidEnterBackground:.
    /// Saves changes in the application's managed object context before the application terminates.
    func applicationWillTerminate(_ application: UIApplication) {
        messageModelService?.stop()
        PEPSession.cleanup()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        guard let messageModelService = messageModelService else {
            Log.shared.error("no networkService")
            return
        }

        messageModelService.checkForNewMails_old() {[unowned self] (numMails: Int?) in
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

// MARK: - User Notifiation

extension AppDelegate {
    private func informUser(numNewMails:Int, completion: @escaping ()->()) {
        GCD.onMain {
            UserNotificationTool.postUserNotification(forNumNewMails: numNewMails)
            completion()
        }
    }
}

// MARK: - Client Certificate Import

extension AppDelegate {

    @discardableResult
    private func handleUrlTheOSHasBroughtUsToForgroundFor(_ url: URL) -> Bool {
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
        guard let topVC = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("We must have a VC at this point.")
            return false
        }
        guard let vc = UIStoryboard.init(name: "Certificates", bundle: nil).instantiateViewController(withIdentifier: ClientCertificateImportViewController.storyboadIdentifier) as? ClientCertificateImportViewController else {
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
