//
//  SettingsCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 19/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//


import XCTest
@testable import pEpForiOS
@testable import MessageModel

class SettingsCellViewModelTest: CoreDataDrivenTestBase {

    var viewModel: SettingsCellViewModel!

    public func testDetail() {
        givenThereIsAWiveModel(with: .showLog)

        XCTAssertEqual(viewModel.value, nil)

        givenThereIsAWiveModel(with: .defaultAccount)

        let detail = viewModel.detail

        XCTAssertEqual(AppSettings.defaultAccount, detail)
    }

    public func testDeleteAccount() {
        setUpViewModel()

        XCTAssertTrue(viewModel.account?.cdAccount() != nil)

        viewModel.delete()

        XCTAssertTrue(viewModel.account?.cdAccount() == nil)
    }

    public func testTitleIsCorrectInShowLog() {
        givenThereIsAWiveModel(with: .showLog)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Logging", comment: ""))
    }

    public func testTitleIsCorrectInCredits() {
        givenThereIsAWiveModel(with: .credits)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Credits", comment: ""))
    }

    public func testTitleIsCorrectInDefaultAccount() {
        givenThereIsAWiveModel(with: .defaultAccount)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Default Account", comment:""))
    }

    public func testTitleIsCorrectInAccount() {
        setUpViewModel()

        let title = viewModel.title

        XCTAssertEqual(title, viewModel.account?.user.address)
    }

    public func testTitleIsCorrectInSetOwnKey() {
        givenThereIsAWiveModel(with: .setOwnKey)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Set Own Key", comment:""))
    }

    public func testGetValue() {
        givenThereIsAWiveModel(with: .showLog)

        XCTAssertEqual(viewModel.value, nil)

        givenThereIsAWiveModel(with: .defaultAccount)

        let value = viewModel.value

        XCTAssertEqual(AppSettings.defaultAccount, value )
    }


    //MARK: Initialization
    private func setUpViewModel() {
        viewModel = SettingsCellViewModel(account: account)
    }

    private func givenThereIsAWiveModel(with type: SettingsCellViewModel.SettingType) {
        viewModel = SettingsCellViewModel(type: type)
    }

}
