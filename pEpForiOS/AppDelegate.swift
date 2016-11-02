//
//  AppDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
import MessageModel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let comp = "AppDelegate"

    var window: UIWindow?

    var appConfig: AppConfig?

    /** Keep open at all times */
    var firstSession: PEPSession?

    let backgroundQueue = OperationQueue()

    func applicationDirectory() -> URL? {
        let fm = FileManager.default
        let dirs = fm.urls(for: .libraryDirectory, in: .userDomainMask)
        return dirs.first
    }

    func dumpFontSizes() {
        let styles = [UIFontTextStyle.body, UIFontTextStyle.caption1, UIFontTextStyle.caption2,
                      UIFontTextStyle.footnote, UIFontTextStyle.headline, UIFontTextStyle.subheadline]
        for sty in styles {
            let font = UIFont.preferredFont(forTextStyle: sty)
            print("\(sty) \(font)")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Open the first session from the main thread and keep it open
        firstSession = PEPSession.init()

        Log.warn(component: comp, "Library url: \(applicationDirectory())")

        setupDefaultSettings()
        loadCoreDataStack()

        DispatchQueue.global(qos: .userInitiated).async {
            AddressBook.checkAndTransfer()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.info(component: comp, "applicationDidEnterBackground")
        appConfig?.model.save()

        // Do mySelf on all accounts
        let accounts = Account.all
        let bgId = application.beginBackgroundTask(expirationHandler: {
            Log.info(component: self.comp, "Could not complete all myself in background")
            self.appConfig?.model.save()

            // Shutdown pEp engine
            self.firstSession = nil
        })
        for acc in accounts {
            let email = acc.user.address
            Log.info(component: comp, "Starting myself for \(email)")
            PEPUtil.myselfFromAccount(acc, queue: backgroundQueue) { identity in
                Log.info(component: self.comp, "Finished myself for \(email) (\(identity[kPepFingerprint]))")
                application.endBackgroundTask(bgId)
            }
        }
        self.appConfig?.model.save()

        // Shutdown pEp engine
        firstSession = nil
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
        appConfig?.model.save()
    }

    func setupDefaultSettings() {
        let settings: [String: AnyObject] = [Constants.kSettingLastAccountEmail: "" as AnyObject]
        UserDefaults.standard.register(defaults: settings)
    }

    func loadCoreDataStack() {
        let objectModel = AppDataModel.appModel()
        do {
            try Record.loadCoreDataStack(
                managedObjectModel: objectModel)
            appConfig = AppConfig()
        } catch {
            print("Error While Loading DataStack")
        }
    }
}
