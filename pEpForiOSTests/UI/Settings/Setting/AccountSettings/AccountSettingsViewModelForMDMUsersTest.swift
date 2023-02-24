//
//  AccountSettingsViewModelForMDMUsersTest.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 07/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class AccountSettingsViewModelForMDMUsersTest: AccountDrivenTestBase {

    var viewModel : AccountSettingsViewModel!

    // Number of sections corresponding to AccountSettingsViewModel's Section Types
    var dummySections : [AccountSettingsViewModel.Section] = [AccountSettingsViewModel.Section]()

    override func setUp() {
        super.setUp()
        setupForMDMUsers()
    }

    private func setupForMDMUsers() {
        let dummyAccountSection = AccountSettingsViewModel.Section(title: "My account", rows:[] , type: .account)
        dummySections.append(dummyAccountSection)
        viewModel = AccountSettingsViewModel(account: account, appSettings: MDMMockAppSettings())
    }

    func testNumberOfSectionsForMDMUsers() throws {
        setupForMDMUsers()
        XCTAssertEqual(viewModel.sections.count, dummySections.count)
    }

    func testNumberOfSections() throws {
        XCTAssertEqual(viewModel.sections.count, dummySections.count)
    }

    func testRowsInFirstSections() {
        let expectedFirstSectionTypes : [AccountSettingsViewModel.RowType] = [.name, .email, .signature, .includeInUnified, .pepSync, .reset]
        let actualFirstSectionTypes = viewModel.sections[0].rows.map { $0.type }
        XCTAssertEqual(actualFirstSectionTypes, expectedFirstSectionTypes)
    }
}
