//
//  KeySyncDeviceGroupUtilMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 18/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
@testable import pEpForiOS

class KeySyncDeviceGroupUtilMoc: KeySyncDeviceGroupUtilProtocol {
    static var didCallLeaveDeviceGroup = false
    static var deviceGroupValueForTest: DeviceGroupState = .grouped

    static var deviceGroupState: DeviceGroupState {
        return deviceGroupValueForTest
    }

    static func leaveDeviceGroup() throws {
        didCallLeaveDeviceGroup = true
    }

    static func isInDeviceGroup() -> Bool {
        fatalError("unimplemented stub")
    }

    static func resetMoc() {
        didCallLeaveDeviceGroup = false
        deviceGroupValueForTest = .grouped
    }
}
