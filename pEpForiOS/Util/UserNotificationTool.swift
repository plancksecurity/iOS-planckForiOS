//
//  UserNotificationTool.swift
//  pEp
//
//  Created by Andreas Buff on 18.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UserNotifications
import pEpIOSToolbox

/// A simple wrapper around Local Notification stuff
struct UserNotificationTool {
    static public func askForPermissions() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound];
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: options) { (granted, error) in }
    }

    static public func post(title: String, body: String? = nil, batch: Int? = nil) {
        // For some reason the notification is not triggered with timeInterval == nil
        let now = 0.01
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        if let body = body {
            content.body = body
        }
        if let batch = batch as NSNumber? {
            content.badge = batch
        }
        content.sound = UNNotificationSound.default
        let identifier = "PEPLocalNotification"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: now, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error) in
            if let error = error {
                Log.shared.warn(
                    "Error posting user notification: %@",
                    "\(error)")
            }
        }
    }

    static public func resetApplicationIconBadgeNumber() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
