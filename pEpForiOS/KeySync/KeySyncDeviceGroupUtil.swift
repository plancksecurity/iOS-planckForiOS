//
//  KeySyncUtil.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol KeySyncUtilProtocol: class {
    static func leaveDeviceGroup(completion: @escaping ()->Void)
    static var isInDeviceGroup: Bool { get }
    static var isKeySyncEnabled: Bool { get }
    static func enableKeySync()
    static func disableKeySync()
}

class KeySyncUtil {

    /// Pure static API.
    private init() {}

    static private var deviceGroupState: DeviceGroupState {
        return AppSettings.shared.lastKnownDeviceGroupState
    }
}

extension KeySyncUtil: KeySyncUtilProtocol {

    static func leaveDeviceGroup(completion: @escaping ()->Void) {
        LeaveDeviceGroupService.leaveDeviceGroup({ (error: Error) in
            Log.shared.errorAndCrash(error: error)
            completion()
        }) {
            completion()
            // Since the UI is updated immediately (see below), ignore.
        }
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
        if isInDeviceGroup {
            leaveDeviceGroup() {
                AppSettings.shared.keySyncEnabled = false
            }
        } else {
            AppSettings.shared.keySyncEnabled = false
        }
    }
}
