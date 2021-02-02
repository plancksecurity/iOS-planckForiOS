//
//  CreditsTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 05.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
import MessageModel

class CreditsTest: XCTestCase {

    func testSwitchReflectedInSettings() throws {
        var expectedValue = true
        let appSettingsMock = AppSettingsMoc(verboseLogginEnabled: expectedValue)
        let creditsViewModel = CreditsViewModel(appSettings: appSettingsMock)
        XCTAssertEqual(expectedValue, appSettingsMock.verboseLogginEnabled)

        expectedValue = !expectedValue
        creditsViewModel.handleVerboseLoggingSwitchChange(newValue: expectedValue)
        XCTAssertEqual(expectedValue, appSettingsMock.verboseLogginEnabled)

        expectedValue = !expectedValue
        creditsViewModel.handleVerboseLoggingSwitchChange(newValue: expectedValue)
        XCTAssertEqual(expectedValue, appSettingsMock.verboseLogginEnabled)
    }
}

class AppSettingsMoc: AppSettingsProtocol {


    init(verboseLogginEnabled: Bool) {
        self.verboseLogginEnabled = verboseLogginEnabled
    }
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

    var verboseLogginEnabled: Bool

    func removeCollapsingStateOfAccountWithAddress(address: String) {

    }

    func collapsedState(forAccountWithAddress address: String) -> Bool {
        return true
    }

    func collapsedState(forFolderNamed folderName: String, ofAccountWithAddress address: String) -> Bool {
        return true
    }

    func setFoldersCollapsedState(address: String, foldersName: [String], isCollapsed: Bool) {

    }

    func setFolderCollapsedState(address: String, folderName: String, isCollapsed: Bool) {

    }

    func setAccountCollapsedState(address: String, isCollapsed: Bool) {

    }

}
