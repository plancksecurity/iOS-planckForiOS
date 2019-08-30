//
//  KeySyncDeviceGroupServiceMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 18/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
@testable import pEpForiOS

class KeySyncDeviceGroupServiceMoc: KeySyncDeviceGroupServiceProtocol {
    var didCallLeaveDeviceGroup = false
    var deviceGroupValueForTest: DeviceGroupState = .grouped

    var deviceGroupState: DeviceGroupState {
        return deviceGroupValueForTest
    }

    func leaveDeviceGroup() throws {
        didCallLeaveDeviceGroup = true
    }
}
