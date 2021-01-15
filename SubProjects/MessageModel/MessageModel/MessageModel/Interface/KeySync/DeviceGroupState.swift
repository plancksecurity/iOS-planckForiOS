//
//  DeviceGroupState.swift
//  MessageModel
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension Notification.Name {

    /// Notification name for KeySync device group state change broadcasts.
    static public let pEpDeviceGroupStateChange = Notification.Name("security.pEp.NotificationNameDeviceGroupStateChange")
}

public enum DeviceGroupState: Int {
    static public let notificationInfoDictKeyDeviceGroupState = "security.pEp.NotificationInfoDictKeyDeviceGroupState"

    case sole = 0
    case grouped = 1
}
