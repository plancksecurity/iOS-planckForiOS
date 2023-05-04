//
//  ReachabilityManager.swift
//  pEpForiOS
//
//  Created by Martín Brude on 11/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif


/// Class to handle the reachability changes.
/// The notifications comes from pEpIOSToolbox
/// It's needed to keep the shared instance alive. 
class ReachabilityManager {

    /// The shared instance
    static public let shared = ReachabilityManager()

    private init() {
        setup()
    }
}

//MARK: - Private

extension ReachabilityManager {

    private func setup() {
        [Notifications.Reachability.connected.name,
         Notifications.Reachability.notConnected.name].forEach { (notification) in
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(changeInternetConnection),
                                                   name: notification, object: nil)
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
