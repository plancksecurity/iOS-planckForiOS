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
    var viewControllerMock = MockNoActivatedAccountViewControler()

    override func setUp() {
        super.setUp()
        viewModel = NoActivatedAccountViewModel(delegate: viewControllerMock)
    }

    func testViewModelNotNil() {
        XCTAssertNotNil(viewModel)
    }

    //MARK: - Sections & Rows

    func testThereAreASectionForEachType() {
        guard let types1 = viewModel?.sections.map({$0.type}) else {
            XCTFail()
            return
        }
        let types2 = NoActivatedAccountViewModel.SectionType.allCases
        for (e1, e2) in zip(types1, types2) {
            if e1 != e2 {
                XCTFail()
            }
        }
    }
}

class MockNoActivatedAccountViewControler: NoActivatedAccountViewController {

}
