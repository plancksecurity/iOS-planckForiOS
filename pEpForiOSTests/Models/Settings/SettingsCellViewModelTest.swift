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
        givenThereIsAViewModel(with: .credits)

        XCTAssertNil(viewModel.detail)

        givenThereIsAViewModel(with: .defaultAccount)

        let detail = viewModel.detail

        XCTAssertEqual(AppSettings.shared.defaultAccount, detail)
    }

    public func testDeleteAccount() {
        givenThereIsAViewModelWithADeleteAccountSpy()

        viewModel.delete()

        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    public func testTitleIsCorrectInCredits() {
        givenThereIsAViewModel(with: .credits)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Credits", comment: ""))
    }

    public func testTitleIsCorrectInDefaultAccount() {
        givenThereIsAViewModel(with: .defaultAccount)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Default Account", comment:""))
    }

    public func testTitleIsCorrectInAccount() {
        setUpViewModel()

        let title = viewModel.title

        XCTAssertEqual(title, viewModel.account?.user.address)
    }

    public func testTitleIsCorrectInSetOwnKey() {
        givenThereIsAViewModel(with: .setOwnKey)

        let title = viewModel.title

        XCTAssertEqual(title, NSLocalizedString("Set Own Key", comment:""))
    }

    public func testGetValue() {
        givenThereIsAViewModel(with: .credits)

        XCTAssertEqual(viewModel.value, nil)

        givenThereIsAViewModel(with: .defaultAccount)

        let value = viewModel.value

        XCTAssertEqual(AppSettings.shared.defaultAccount, value )
    }


    //MARK: Initialization
    private func setUpViewModel(with account: Account) {
        let messageModelServiceMoc = MessageModelServiceMoc()
        viewModel = SettingsCellViewModel(account: account,
                                          messageModelService: messageModelServiceMoc)
    }

    private func setUpViewModel() {
        setUpViewModel(with: account)
    }

    private func givenThereIsAViewModel(with type: SettingsCellViewModel.SettingType) {
        viewModel = SettingsCellViewModel(type: type)
    }

    private func givenThereIsAViewModelWithADeleteAccountSpy() {
        let account = AccountSpy(withDataFrom: self.account)
        account.didCallDeleteExpectation = expectation(description: AccountSpy.DELETE_ACCOUNT_DESCRIPTION)
        setUpViewModel(with: account)
    }

    class AccountSpy: Account {

        static let DELETE_ACCOUNT_DESCRIPTION = "DELETE CALLED"

        var didCallDeleteExpectation: XCTestExpectation?

        func delete() {
            didCallDeleteExpectation?.fulfill()
        }
    }

}
