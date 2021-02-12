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
        let appSettingsMock = MockAppSettings(verboseLogginEnabled: expectedValue)
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
