//
//  AccountPickerViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 11.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class AccountPickerViewModelTest: AccountDrivenTestBase {

    // MARK: - numAccounts

    func testNumAccounts_num0() {
        deleteAllAccounts()
        let expectedNumAccounts = 0
        assertPickerViewModel(numAccounts: expectedNumAccounts)
    }

    func testNumAccounts_num1() {
        let expectedNumAccounts = 1
        assertPickerViewModel(numAccounts: expectedNumAccounts)
    }

    func testNumAccounts_num2() {
        createAndSaveSecondAccount()
        let expectedNumAccounts = 2
        assertPickerViewModel(numAccounts: expectedNumAccounts)
    }

    // MARK: - account(at:)

    func testAccountAt_0() {
        let testIdx = 0
        assertPickerViewModel(accountAt: testIdx, expected: account)
    }

    func testAccountAt_1() {
        let _ = createAndSaveSecondAccount()
        let sndIdx = 1

        assertPickerViewModel(accountAt: sndIdx, expected: secondAccount())
    }

    func testAccountAt_not1() {
        createAndSaveSecondAccount()
        let testIdx = 1

        assertPickerViewModel(accountAt: testIdx,
                              expected: firstAccount(),
                              shouldFail: true)
    }

    //MARK: - row(at:)
    func testRowForAccountAt_0() {
        createAndSaveSecondAccount()
        let expectedAccountIndex = 0
        assertPickerViewModel(account: firstAccount().user.address, expectedPosition: expectedAccountIndex)
    }

    func testRowForAccountAt_1() {
        let second = createAndSaveSecondAccount()
        let expectedAccountIndex = 1
        assertPickerViewModel(account: second.user.address, expectedPosition: expectedAccountIndex)
    }

    func testRowForAccountNotAt_0() {
        let second = createAndSaveSecondAccount()
        let expectedAccountIndex = 0
        assertPickerViewModel(account: second.user.address,
                              expectedPosition: expectedAccountIndex,
                              shouldFail: true)
    }

    func testRowForAccountNotAt_1() {
        createAndSaveSecondAccount()
        let expectedAccountIndex = 1
        assertPickerViewModel(account: firstAccount().user.address,
                              expectedPosition: expectedAccountIndex,
                              shouldFail: true)
    }

    // MARK: - handleUserSelected

    func testHandleUserSelected_oneAccount_correct() {
        let firstRowIdx = 0
        assertUserSelection(selectIdx: firstRowIdx,
                            accountToCompare: account,
                            mustEqualSelected: true)
    }

    func testHandleUserSelected_twoAccounts_correct() {
        let secondRowIdx = 1
        let _ = createAndSaveSecondAccount()

        assertUserSelection(selectIdx: secondRowIdx,
                            accountToCompare: secondAccount(),
                            mustEqualSelected: true)
    }

    func testHandleUserSelected_twoAccounts_shouldFail() {
        let firstAccountIdx = 0
        let _ = createAndSaveSecondAccount()

        assertUserSelection(selectIdx: firstAccountIdx,
                            accountToCompare: secondAccount(),
                            mustEqualSelected: false)
    }

    // MARK: - HELPER

    func assertUserSelection(selectIdx: Int, accountToCompare: Account, mustEqualSelected: Bool) {
        let expectDidSelectCalled = expectation(description: "expectDidSelectCalled")
        let testDelegate = TestResultDelegate(expectDidSelectCalled: expectDidSelectCalled,
                                              accountToCompare: accountToCompare,
                                              mustEqualSelected: mustEqualSelected)
        let testee = AccountPickerViewModel(resultDelegate: testDelegate)
        testee.handleUserSelected(row: selectIdx)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    private func assertPickerViewModel(accountAt idx: Int,
                                       expected: Account,
                                       shouldFail: Bool = false) {
        let vm = AccountPickerViewModel(resultDelegate: nil)
        let testee = vm.account(at: idx)
        if shouldFail {
            XCTAssertNotEqual(testee, expected.user.address)
        } else {
            XCTAssertEqual(testee, expected.user.address)
        }
    }

    private func assertPickerViewModel(account: String,
                                       expectedPosition: Int,
                                       shouldFail: Bool = false) {
        let vm = AccountPickerViewModel(resultDelegate: nil)
        let testee = vm.row(at: account)
        if shouldFail {
            XCTAssertNotEqual(testee, expectedPosition)
        } else {
            XCTAssertEqual(testee, expectedPosition)
        }
    }

    private func assertPickerViewModel(numAccounts: Int) {
        let testee = AccountPickerViewModel(resultDelegate: nil)
        let numAccountsInDB = Account.all().count
        XCTAssertEqual(testee.numAccounts, numAccountsInDB)
        XCTAssertEqual(testee.numAccounts, numAccounts)
    }

    @discardableResult private func createAndSaveSecondAccount () -> Account {
        let secondAccount = TestData().createWorkingAccount(number: 1)
        secondAccount.session.commit()
        return secondAccount
    }

    private func deleteAllAccounts() {
        Account.all().forEach { $0.delete() }
    }

    private func account(at: Int) -> Account {
        return Account.all()[at]
    }

    private func firstAccount() -> Account {
        return account(at: 0)
    }

    private func secondAccount() -> Account {
        return account(at: 1)
    }
}

// MARK: TestResultDelegate

extension AccountPickerViewModelTest {

    class TestResultDelegate: AccountPickerViewModelResultDelegate {
        let expectDidSelectCalled: XCTestExpectation
        let accountToCompare: Account
        let mustEqualSelected: Bool

        init(expectDidSelectCalled: XCTestExpectation,
             accountToCompare: Account,
             mustEqualSelected: Bool = true) {
            self.expectDidSelectCalled = expectDidSelectCalled
            self.accountToCompare = accountToCompare
            self.mustEqualSelected = mustEqualSelected
        }

        func accountPickerViewModel(_ vm: AccountPickerViewModel, didSelect account: Account) {
            expectDidSelectCalled.fulfill()
            if mustEqualSelected {
                XCTAssertEqual(accountToCompare, account)
            } else {
                XCTAssertNotEqual(accountToCompare, account)
            }
        }
    }
}
