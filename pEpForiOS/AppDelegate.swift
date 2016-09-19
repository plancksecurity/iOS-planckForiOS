 //
//  AppDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let comp = "AppDelegate"

    var window: UIWindow?

    let appConfig: AppConfig = AppConfig()

    /** Keep open at all times */
    var firstSession: PEPSession?

    let backgroundQueue = NSOperationQueue.init()

    /**
     Use for development. Remove all mails so they are fetched again.
     */
    func removeAllMails() {
        let model = Model.init(context: appConfig.coreDataUtil.managedObjectContext)
        if let folders = model.foldersByPredicate(NSPredicate.init(value: true)) {
            for folder in folders {
                model.context.deleteObject(folder as! NSManagedObject)
            }
            model.save()
        }
    }

    func applicationDirectory() -> NSURL? {
        let fm = NSFileManager.defaultManager()
        let dirs = fm.URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)
        return dirs.first
    }

    func dumpFontSizes() {
        let styles = [UIFontTextStyleBody, UIFontTextStyleCaption1, UIFontTextStyleCaption2,
                      UIFontTextStyleFootnote, UIFontTextStyleHeadline, UIFontTextStyleSubheadline]
        for sty in styles {
            let font = UIFont.preferredFontForTextStyle(sty)
            print("\(sty) \(font)")
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [NSObject: AnyObject]?) -> Bool {

        // Open the first session from the main thread and keep it open
        firstSession = PEPSession.init()

        Log.warnComponent(comp, "Library url: \(applicationDirectory())")

        AddressBook.checkAndTransfer(appConfig.coreDataUtil)
        setupDefaultSettings()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        Log.infoComponent(comp, "applicationDidEnterBackground")
        appConfig.model.save()

        // Do mySelf on all accounts
        if let accounts = appConfig.model.accountsByPredicate(nil, sortDescriptors: nil) {
            let bgId = application.beginBackgroundTaskWithExpirationHandler() {
                Log.infoComponent(self.comp, "Could not complete all myself in background")
                self.appConfig.model.save()

                // Shutdown pEp engine
                self.firstSession = nil
            }
            for acc in accounts {
                let email = acc.email
                Log.infoComponent(comp, "Starting myself for \(email)")
                PEPUtil.myselfFromAccount(acc, queue: backgroundQueue) { identity in
                    Log.infoComponent(self.comp, "Finished myself for \(email) (\(identity[kPepFingerprint]))")
                    application.endBackgroundTask(bgId)
                }
            }
            self.appConfig.model.save()

            // Shutdown pEp engine
            firstSession = nil
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Open the first session from the main thread and keep it open
        firstSession = PEPSession.init()

        AddressBook.checkAndTransfer(appConfig.coreDataUtil)
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        appConfig.model.save()
    }

    func setupDefaultSettings() {
        let settings: [String:AnyObject] = [Account.kSettingLastAccountEmail:""]
        NSUserDefaults.standardUserDefaults().registerDefaults(settings)
    }
}