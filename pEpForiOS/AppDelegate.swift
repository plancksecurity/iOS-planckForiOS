//
//  AppDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let comp = "AppDelegate"

    var window: UIWindow?

    var appConfig: AppConfig?

    /** Keep open at all times */
    var firstSession: PEPSession?

    /** The SMTP/IMAP backend */
    var networkService: NetworkService?

    let backgroundQueue = OperationQueue()

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
        appearance()

        Log.warn(component: comp, content: "Library url: \(applicationDirectory())")

        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // If unit tests are running, leave the stage for them
            // and pretty much don't do anything.
            return false
        }

        // Open the first session from the main thread and keep it open
        firstSession = PEPSession()

        setupDefaultSettings()

        loadCoreDataStack()

        networkService = NetworkService()
        CdAccount.sendLayer = networkService

        DispatchQueue.global(qos: .userInitiated).async {
            AddressBook.checkAndTransfer()
        }

        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.info(component: comp, content: "applicationDidEnterBackground")

        var bgId = 0
        bgId = application.beginBackgroundTask(expirationHandler: {
            // Shutdown pEp engine
            self.firstSession = nil
            application.endBackgroundTask(bgId)
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Open the first session from the main thread and keep it open
        firstSession = PEPSession()

        DispatchQueue.global(qos: .userInitiated).async {
            AddressBook.checkAndTransfer()
        }
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

    func setupDefaultSettings() {
        let settings: [String: AnyObject] = [Constants.kSettingLastAccountEmail: "" as AnyObject]
        UserDefaults.standard.register(defaults: settings)
    }

    func loadCoreDataStack() {
        let objectModel = MessageModelData.MessageModelData()
        do {
            try Record.loadCoreDataStack(
                managedObjectModel: objectModel)
            appConfig = AppConfig()
        } catch {
            print("Error While Loading DataStack")
        }
    }
    
    fileprivate final func appearance() {
        UINavigationBar.appearance().backgroundColor = .pEpColor
        UINavigationBar.appearance().barTintColor = .pEpColor
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.white]
        
        UIToolbar.appearance().backgroundColor = .pEpColor
        UIToolbar.appearance().barTintColor = .pEpColor
        UIToolbar.appearance().tintColor = .white
        
        UITextView.appearance().tintColor = .pEpColor
        UITextField.appearance().tintColor = .pEpColor
        
        UISearchBar.appearance().barTintColor = .pEpColor
        UISearchBar.appearance().backgroundColor = .pEpColor
        UISearchBar.appearance().tintColor = .white
    }
}
