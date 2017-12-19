//
//  UserNotificationTool.swift
//  pEp
//
//  Created by Andreas Buff on 18.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UserNotifications

/// A simple wrapper around Local Notification stuff
struct UserNotificationTool {
    //BUFF: TODO: iOS<10 compatibility
    static public func askForPermissions(completion: ((_ granted: Bool) -> Void)? = nil) {
        if #available(iOS 10, *) {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound];
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: options) {
                (granted, error) in
                completion?(granted)
            }
        } else {
            Log.shared.errorAndCrash(component: #function, errorString: "Unimplemented stub")
        }
    }

    static func isAuthorized(completion: ((_ authorized: Bool) -> Void)? = nil){
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { (settings) in
                completion?(settings.authorizationStatus == .authorized)
            }
        } else {
            Log.shared.errorAndCrash(component: #function, errorString: "Unimplemented stub")
        }
    }

    static public func post(title: String, body: String? = nil, batch: Int?) {
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            if let body = body {
                content.body = body
            }
            if let batch = batch as NSNumber? {
                content.badge = batch
            }
            content.sound = UNNotificationSound.default()

            let identifier = "PEPLocalNotification"
            // For some reason the notification is not triggered with timeInterval == nil
            let now = 0.01
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: now, repeats: false)
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            center.add(request) { (error) in
                if let error = error {
                    Log.shared.warn(component: #function,
                                    content: "Error posting user notification: \(error)")
                }
            }
        } else {
            Log.shared.errorAndCrash(component: #function, errorString: "Unimplemented stub")
        }
    }

    static public func resetApplicationIconBadgeNumber() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
