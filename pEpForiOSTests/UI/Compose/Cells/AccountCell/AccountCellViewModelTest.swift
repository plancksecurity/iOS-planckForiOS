//
//  AccountCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class AccountCellViewModelTest: XCTestCase {

    /*
     PUBLIC API

     public var displayAccount: String? {
     return selectedAccount?.user.address
     }

     init(resultDelegate: AccountCellViewModelResultDelegate, initialAccount: Account? = nil) {
     self.resultDelegate = resultDelegate
     selectedAccount = initialAccount
     }

     public var accountPickerViewModel: AccountPickerViewModel {
     return AccountPickerViewModel(resultDelegate: self)
     }

     */

   // MARK: - Helper

    private func assert(initialAccount: Account? = nil,
                        accountChangedMustBeCalled: Bool?,
                        expectedAccount: Account?) {
        var expAccountChangedToCalled: XCTestExpectation? = nil
        var expAccountChangedCalled: XCTestExpectation? = nil
        if let weCare = accountChangedMustBeCalled {
            expAccountChangedToCalled = expectation(inverted: weCare)
            expAccountChangedCalled = expectation(inverted: weCare)
        }
        let resultDelegate = TestResultDelegate(expAccountChangedToCalled: expAccountChangedToCalled,
                                                expectedAccount: expectedAccount ?? nil)
        let delegate = TestDelegate(expAccountChangedCalled: expAccountChangedCalled,
                                    expectedAddress: expectedAccount?.user.address ?? nil)
        let vm = AccountCellViewModel(resultDelegate: resultDelegate,
                                      initialAccount: initialAccount)
        vm.delegate = delegate
    }

    private class TestResultDelegate: AccountCellViewModelResultDelegate {
        let expAccountChangedToCalled: XCTestExpectation?
        let expectedAccount: Account?

        init(expAccountChangedToCalled: XCTestExpectation?, expectedAccount: Account?) {
            self.expAccountChangedToCalled = expAccountChangedToCalled
            self.expectedAccount = expectedAccount
        }

        func accountCellViewModel(_ vm: AccountCellViewModel, accountChangedTo account: Account) {
            guard let exp = expAccountChangedToCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedAccount {
                XCTAssertEqual(account, expected)
            }
        }
    }

    private class TestDelegate: AccountCellViewModelDelegate {
        let expAccountChangedCalled: XCTestExpectation?
        let expectedAddress: String?

        init(expAccountChangedCalled: XCTestExpectation?, expectedAddress: String?) {
            self.expAccountChangedCalled = expAccountChangedCalled
            self.expectedAddress = expectedAddress
        }

        func accountChanged(newValue: String) {
            guard let exp = expAccountChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedAddress {
                XCTAssertEqual(newValue, expected)
            }
        }
    }
}
