//
//  KeySyncUtilMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 18/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
@testable import pEpForiOS

class KeySyncUtilMoc: KeySyncUtilProtocol {
    static var didCallLeaveDeviceGroup = false
    static var deviceGroupValueForTest: DeviceGroupState = .grouped

    // MARK: - KeySyncUtilProtocol

    static func enableKeySync() {
        fatalError("unimplemented stub")
    }

    static func disableKeySync() {
        fatalError("unimplemented stub")
    }

    static var deviceGroupState: DeviceGroupState {
        return deviceGroupValueForTest
    }

    static func leaveDeviceGroup(completion: @escaping ()->Void) {
        didCallLeaveDeviceGroup = true
    }

    static var isKeySyncEnabled: Bool {
        fatalError("unimplemented stub")
    }

    static var isInDeviceGroup: Bool {
        fatalError("unimplemented stub")
    }

    static func resetMoc() {
        didCallLeaveDeviceGroup = false
        deviceGroupValueForTest = .grouped
    }
}
