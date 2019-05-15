//
//  TrustedServerSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 22/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
import MessageModel

class TrustedServerSettingsViewModelTest: CoreDataDrivenTestBase {

    var viewModel: TrustedServerSettingsViewModel!

    public func testSetStoreSecurely() {
        let account = cdAccount.account()
        setUpViewModel()

        viewModel.setStoreSecurely(forAccountWith: account.user.address, toValue: false)
        var accountInTrustedServer = AppSettings.isManuallyTrustedServer(address: account.user.address)
        XCTAssertTrue(accountInTrustedServer)

        viewModel.setStoreSecurely(forAccountWith: account.user.address, toValue: true)
        accountInTrustedServer = AppSettings.isManuallyTrustedServer(address: account.user.address)
        XCTAssertFalse(accountInTrustedServer)
    }

    private func setUpViewModel() {
        viewModel = TrustedServerSettingsViewModel()
    }
}
