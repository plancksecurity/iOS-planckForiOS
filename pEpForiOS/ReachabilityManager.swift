//
//  ReachabilityManager.swift
//  pEpForiOS
//
//  Created by Martín Brude on 11/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

// https://gist.github.com/dimohamdy/5166ba6c88f6954fa6b23bc9f28cbe12

class ReachabilityManager {
    static public let shared = ReachabilityManager()
//    public let reachability: Reachability2
    public let netConnection = NetMonitor.shared

    private init() {
//        reachability = Reachability2.shared
//        setup()
//        reachability.startNetworkReachabilityObserver()
    }

    private func setup() {
        [Notifications.Reachability.connected.name,
         Notifications.Reachability.notConnected.name].forEach { (notification) in
            NotificationCenter.default.addObserver(self, selector: #selector(changeInternetConnection), name: notification, object: nil)
         }
    }

    @objc
    private func changeInternetConnection(notification: Notification) {
        handleReachabilityChange(notification: notification)
    }

    private func handleReachabilityChange(notification: Notification) {
        if notification.name == Notifications.Reachability.notConnected.name {
            UIUtils.showNoInternetConnectionBanner()
        } else {
            UIUtils.hideBanner(shouldSavePreference: true)
        }
    }
}
