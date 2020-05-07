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

class TrustedServerSettingsViewModelTest: AccountDrivenTestBase {

    var viewModel: TrustedServerSettingsViewModel!

    public func testSetStoreSecurely() {
        setUpViewModel()

        guard let indexPath = indexPath(account: account) else {
            XCTFail("Fail to get account indexPath")
            return
        }

        viewModel.setStoreSecurely(indexPath: indexPath, toValue: false)
        guard let isTrusted =
            Account.Fetch.accountAllowedToManuallyTrust(fromAddress: account.user.address)?
            .imapServer?.manuallyTrusted else {
                XCTFail()
                return
        }
        XCTAssertTrue(isTrusted)

        viewModel.setStoreSecurely(indexPath: indexPath, toValue: true)
        guard let isTrustedAfterChange =
            Account.Fetch.accountAllowedToManuallyTrust(
                fromAddress: account.user.address)?.imapServer?.manuallyTrusted else {
            XCTFail()
            return
        }
        XCTAssertFalse(isTrustedAfterChange)
    }
}

// MARK: - Private

extension TrustedServerSettingsViewModelTest {
    private func setUpViewModel() {
        viewModel = TrustedServerSettingsViewModel()
    }

    private func indexPath(account: Account) -> IndexPath? {
        for (index, row) in viewModel.rows.enumerated() {
            if row.address == account.user.address {
                return IndexPath(row: index, section: 0)
            }
        }
        return nil
    }
 }
