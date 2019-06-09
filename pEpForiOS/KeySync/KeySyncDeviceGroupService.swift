//
//  KeySyncDeviceGroupService.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

class KeySyncDeviceGroupService {

    static var deviceGroupState: DeviceGroupState {
        return AppSettings.lastKnownDeviceGroupState
    }

    static func leaveDeviceGroup() throws {
        try PEPSession().leaveDeviceGroupError()  //!!!: @dirk: rename in leaveDeviceGroupError
    }
}

extension KeySyncDeviceGroupService: KeySyncServiceDeviceGroupDelegate {
    func deviceGroupStateChanged(newValue: DeviceGroupState) {
        AppSettings.lastKnownDeviceGroupState = newValue
    }
}
