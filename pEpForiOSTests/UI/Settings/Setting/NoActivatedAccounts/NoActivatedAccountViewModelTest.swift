//
//  NoActivatedAccountViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 11/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class NoActivatedAccountViewModelTest: AccountDrivenTestBase {
    var viewModel : NoActivatedAccountViewModel!
    var viewControllerMock = MockNoActivatedAccountViewController()

    override func setUp() {
        super.setUp()

        //At least one inactive account is required.
        account.isActive = false
        account.session.commit()

        viewModel = NoActivatedAccountViewModel(delegate: viewControllerMock)
    }

    func testViewModelNotNil() {
        XCTAssertNotNil(viewModel)
    }

    //MARK: - Sections & Rows

    func testSectionsAreCorrectlyGenerated() {
        let types1 = viewModel.sections.map({$0.type})
        let types2 = NoActivatedAccountViewModel.SectionType.allCases
        for (e1, e2) in zip(types1, types2) {
            if e1 != e2 {
                XCTFail()
            }
        }
    }

    func testRowsInAccountsSectionAreCorrectlyGenerated() {
        guard let accountSectionIndex = NoActivatedAccountViewModel.SectionType.accounts.index else {
            return XCTFail()
        }
        let rowTypesForAccountsSection = viewModel.sections[accountSectionIndex].rows.map({$0.type})
        let accountRowTypes: [NoActivatedAccountViewModel.RowType] = NoActivatedAccountViewModel.RowType.allCases

        for (e1, e2) in zip(rowTypesForAccountsSection, accountRowTypes) {
            if e1 != e2 {
                XCTFail()
            }
        }
    }

    func testSwitchRowPressed() {
        let dismissYourselfExpectation = expectation(description: "dismissYourselfExpectation")
        var viewControllerMock = MockNoActivatedAccountViewController(dismissYourselfExpectation: dismissYourselfExpectation)
        viewModel = NoActivatedAccountViewModel(delegate: viewControllerMock)

        viewModel.section[]
    }
}

class MockNoActivatedAccountViewController: NoActivatedAccountViewController {

    private var dismissYourselfExpectation: XCTestExpectation?
    private var showAccountSetupViewExpectation: XCTestExpectation?

    init(dismissYourselfExpectation: XCTestExpectation? = nil,
         showAccountSetupViewExpectation: XCTestExpectation? = nil) {
        self.dismissYourselfExpectation = dismissYourselfExpectation
        self.showAccountSetupViewExpectation = showAccountSetupViewExpectation
    }

    override func dismissYourself() {
        fulfillIfNotNil(expectation: dismissYourselfExpectation)
    }

    func showAccountSetupView() {
        fulfillIfNotNil(expectation: showAccountSetupViewExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }
}
