//
//  KeySyncDeviceGroupUtil.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

protocol KeySyncDeviceGroupUtilProtocol: class {
    static var deviceGroupState: DeviceGroupState { get }
    static func leaveDeviceGroup() throws
    static func isInDeviceGroup() -> Bool
}

class KeySyncDeviceGroupUtil: KeySyncDeviceGroupUtilProtocol {

    /// Pure static API.
    private init() {}

    static var deviceGroupState: DeviceGroupState {
        return AppSettings.shared.lastKnownDeviceGroupState
    }

    static func leaveDeviceGroup() throws {
        try PEPSession().leaveDeviceGroup()
        AppSettings.shared.lastKnownDeviceGroupState = .sole
    }

    static func isInDeviceGroup() -> Bool {
        return deviceGroupState == .grouped
    }
}
