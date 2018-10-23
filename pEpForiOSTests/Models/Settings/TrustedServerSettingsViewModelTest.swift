//
//  TrustedServerSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 22/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class TrustedServerSettingsViewModelTest: CoreDataDrivenTestBase {

    var viewModel: TrustedServerSettingsViewModel!

    public func testSetStoreSecurely() {
        setUpViewModel()

        viewModel.setStoreSecurely(forAccountWith: account.user.address, toValue: false)
        var accountInTrustedServer = AppSettings.isManuallyTrustedServer(address: "iostest006@peptest.ch")
        XCTAssertTrue(accountInTrustedServer)

        viewModel.setStoreSecurely(forAccountWith: account.user.address, toValue: true)
        accountInTrustedServer = AppSettings.isManuallyTrustedServer(address: "iostest006@peptest.ch")
        XCTAssertFalse(accountInTrustedServer)


    }

    private func setUpViewModel() {
        viewModel = TrustedServerSettingsViewModel()
    }
}
