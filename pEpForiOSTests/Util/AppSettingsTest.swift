//
//  AppSettingsTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 1/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class AppSettingsTest: XCTestCase {

    let appSettingsMoc = MockAppSettings()
    func testSetCollapsingStateForAccount() {

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}


class MockAppSettings: AppSettingsProtocol {

    var keySyncEnabled: Bool = false

    var usePEPFolderEnabled: Bool = false

    var extraKeysEditable: Bool = false

    var unencryptedSubjectEnabled: Bool = false

    var threadedViewEnabled: Bool = false

    var passiveMode: Bool = false

    var defaultAccount: String? = nil

    var lastKnownDeviceGroupState: DeviceGroupState = .sole

    var shouldShowTutorialWizard: Bool = false

    var userHasBeenAskedForContactAccessPermissions: Bool = false

    var unsecureReplyWarningEnabled: Bool = false

    var verboseLogginEnabled: Bool = false


    func removeCollapsingStateOfAccountWithAddress(address: String) {

    }

    func collapsedState(forAccountWithAddress address: String) -> Bool {

        return true
    }

    func collapsedState(forFolderNamed folderName: String, ofAccountWithAddress address: String) -> Bool {
        return true
    }


}
