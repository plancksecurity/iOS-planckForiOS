//
//  AppSettings+KeySyncDeviceGroupStateChangeNotification.swift
//  pEp
//
//  Created by Andreas Buff on 15.11.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

import pEpIOSToolbox

// MARK: - AppSettings+KeySyncDeviceGroupStateChangeNotification

extension AppSettings {

    func registerForKeySyncDeviceGroupStateChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceGroupStateChangeNotification(_:)),
                                               name: Notification.Name.pEpDeviceGroupStateChange,
                                               object: nil)
    }

    @objc
    private func handleDeviceGroupStateChangeNotification(_ notification: Notification) {
        guard
            let newState = notification.userInfo?[DeviceGroupState.notificationInfoDictKeyDeviceGroupState] as? DeviceGroupState
            else {
                Log.shared.errorAndCrash("Missing data")
                return
        }
        AppSettings.shared.lastKnownDeviceGroupState = newState
    }

    func registerForKeySyncDisabledByEngineNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeySyncDisabledByEngineNotification),
                                               name: Notification.Name.pEpKeySyncDisabledByEngine,
                                               object: nil)
    }

    @objc
    private func handleKeySyncDisabledByEngineNotification(_ notification: Notification) {
        AppSettings.shared.keySyncEnabled = false
    }
}
