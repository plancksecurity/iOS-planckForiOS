//
//  KeySyncUtil.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

protocol KeySyncUtilProtocol: class {
    static var deviceGroupState: DeviceGroupState { get }
    static func leaveDeviceGroup() throws
    static var isInDeviceGroup: Bool { get }
    static var isKeySyncEnabled: Bool { get }
    static func enableKeySync()
    static func disableKeySync()

}

class KeySyncUtil: KeySyncUtilProtocol {

    /// Pure static API.
    private init() {}

    static var deviceGroupState: DeviceGroupState {
        return AppSettings.shared.lastKnownDeviceGroupState
    }

    static func leaveDeviceGroup() throws {
        try PEPSession().leaveDeviceGroup()
        // We do that here to update the UI imediatelly (fake responsivenes)
        AppSettings.shared.lastKnownDeviceGroupState = .sole
    }

    static var isInDeviceGroup: Bool {
        return deviceGroupState == .grouped
    }

    static var isKeySyncEnabled: Bool {
        return AppSettings.shared.keySyncEnabled
    }

    static func enableKeySync() {
        AppSettings.shared.keySyncEnabled = true
    }

    static func disableKeySync() {
        AppSettings.shared.keySyncEnabled = false
    }
}
