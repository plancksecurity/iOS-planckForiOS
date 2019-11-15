//
//  AppSettings+KeySyncDeviceGroupStateChangeNotification.swift
//  pEp
//
//  Created by Andreas Buff on 15.11.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol KeySyncDeviceGroupStateChangeNotificationHandlerProtocol {
    func handleDeviceGroupStateChangeNotification(userInfo: [String:Any])
}

// MARK: - AppSettings+KeySyncDeviceGroupStateChangeNotification

extension AppSettings {

    func registerForKeySyncDeviceGroupStateChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceGroupStateChangeNotification(userInfo:)),
                                               name: Notification.Name.pEpDeviceGroupStateChange,
                                               object: nil)
    }

    @objc
    private func handleDeviceGroupStateChangeNotification(userInfo: [String: Any]) {
        guard
            let newState = userInfo[DeviceGroupState.notificationInfoDictKeyDeviceGroupState] as? DeviceGroupState
            else {
                Log.shared.errorAndCrash("Missing data")
                return
        }
        AppSettings.shared.lastKnownDeviceGroupState = newState
    }
}
