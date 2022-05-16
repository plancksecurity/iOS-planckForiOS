//
//  ReachabilityManager.swift
//  pEpForiOS
//
//  Created by Martín Brude on 11/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class ReachabilityManager {
    static public let shared = ReachabilityManager()
    public let networkMonitorUtil = NetworkMonitorUtil.shared

    private init() {
        setup()
    }

    private func setup() {
        [Notifications.Reachability.connected.name,
         Notifications.Reachability.notConnected.name].forEach { (notification) in
            NotificationCenter.default.addObserver(self, selector: #selector(changeInternetConnection), name: notification, object: nil)
         }
    }

    @objc
    private func changeInternetConnection(notification: Notification) {
        if notification.name == Notifications.Reachability.notConnected.name {
            UIUtils.showNoInternetConnectionBanner()
        } else {
            UIUtils.hideBanner()
        }
    }
}
