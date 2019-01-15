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
    static public func askForPermissions(completion: ((_ granted: Bool) -> Void)? = nil) {
        if #available(iOS 10, *) {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound];
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: options) {
                (granted, error) in
                completion?(granted)
            }
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types:
                [.alert, .badge, .sound], categories: nil))
            isAuthorized() { granted in
                completion?(granted)
            }
        }
    }

    static func isAuthorized(completion: ((_ authorized: Bool) -> Void)? = nil){
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { (settings) in
                completion?(settings.authorizationStatus == .authorized)
            }
        } else {
            guard let grantedTypes = UIApplication.shared.currentUserNotificationSettings?.types else {
                completion?(false)
                return
            }
            completion?(grantedTypes.contains(.alert))
        }
    }

    static public func post(title: String, body: String? = nil, batch: Int? = nil) {
        // For some reason the notification is not triggered with timeInterval == nil
        let now = 0.01

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
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: now, repeats: false)
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            center.add(request) { (error) in
                if let error = error {
                    Logger.utilLogger.warn(
                        "Error posting user notification: %{public}@",
                        error.localizedDescription)
                }
            }
        } else {
            let notification = UILocalNotification()
            notification.fireDate = Date(timeIntervalSinceNow: now)
            notification.alertBody = title
            if let body = body {
                notification.alertAction = body
            }
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared.scheduleLocalNotification(notification)

            if let batch = batch {
                setApplicationIconBadgeNumber(batch)
            }
        }
    }

    static public func resetApplicationIconBadgeNumber() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    static public func setApplicationIconBadgeNumber(_ num: Int) {
        UIApplication.shared.applicationIconBadgeNumber = num
    }
}
