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

    func application(application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [NSObject: AnyObject]?) -> Bool {
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
        if let accounts = appConfig.model.accountsByPredicate(nil, sortDescriptors: nil) {
            for acc in accounts {
                let email = acc.email
                let bgId = application.beginBackgroundTaskWithExpirationHandler() {
                    Log.infoComponent(self.comp, "Could not myself for \(email)")
                }
                PEPUtil.myselfFromAccount(acc) { identity in
                    Log.infoComponent(self.comp, "Finished myself for \(email) (\(identity[kPepFingerprint]))")
                    application.endBackgroundTask(bgId)
                }
            }
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
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

