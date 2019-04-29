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
        let account = cdAccount.account()
        setUpViewModel()

        viewModel.setStoreSecurely(forAccountWith: account.user.address, toValue: false)
        guard let isTrusted = Account.Fetch.getAccountAllowedToManuallyTrust(account.user.address)?
            .imapServer?.manuallyTrusted else {
                XCTFail()
                return
        }
        XCTAssertTrue(isTrusted)

        viewModel.setStoreSecurely(forAccountWith: account.user.address, toValue: true)
        guard let isTrustedAfterChange =
            Account.Fetch.getAccountAllowedToManuallyTrust(account.user.address)?.imapServer?
                .manuallyTrusted else {
            XCTFail()
            return
        }
        XCTAssertFalse(isTrustedAfterChange)
    }

    private func setUpViewModel() {
        viewModel = TrustedServerSettingsViewModel()
    }
}
