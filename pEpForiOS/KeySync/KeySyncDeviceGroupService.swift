//
//  KeySyncDeviceGroupService.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

protocol KeySyncDeviceGroupServiceProtocol: class {
    var deviceGroupState: DeviceGroupState { get }
    func leaveDeviceGroup() throws
}

final class KeySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol {
    var deviceGroupState: DeviceGroupState {
        return AppSettings.lastKnownDeviceGroupState
    }

    func leaveDeviceGroup() throws {
        try PEPSession().leaveDeviceGroupError()  //!!!: @dirk: rename in leaveDeviceGroupError
        AppSettings.lastKnownDeviceGroupState = .sole
    }
}

extension KeySyncDeviceGroupService: KeySyncServiceDeviceGroupDelegate {
    func deviceGroupStateChanged(newValue: DeviceGroupState) {
        AppSettings.lastKnownDeviceGroupState = newValue
    }
}
