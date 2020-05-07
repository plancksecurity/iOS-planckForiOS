//
//  FilterViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 02/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class FilterViewModelTest: AccountDrivenTestBase {
    var accounts = [Account]()

    override func setUp() {
        super.setUp()
    }

    func testCreateCorrectAccountCell() {
        givenThereAreTwoAccounts()
        let viewmodel = FilterViewModel(filter: MessageQueryResultsFilter(accounts: accounts))
        XCTAssertEqual(viewmodel[0].count, accounts.count)
    }

    func testCreateCorrectIncludeCells() {
        givenThereAreTwoAccounts()
        let viewmodel = FilterViewModel(filter: MessageQueryResultsFilter(mustBeFlagged: true,
                                                                          mustBeUnread: true,
                                                                          mustContainAttachments: nil,
                                                                          accounts: accounts))
        XCTAssertEqual(viewmodel[0].count, accounts.count)
    }

    /*
    func testCreateCorrectOtherCells() {
        let otherFilters = [AttachmentFilterTest.self]
        let viewmodel = FilterViewModel(type: .other)
        XCTAssertEqual(otherFilters.count, viewmodel.count)
    }
     */

    //MARK: Initialization
    func givenThereAreTwoAccounts() {
        let acc1 = TestData().createWorkingAccount(number: 0)
        acc1.save()
        let acc2 = TestData().createWorkingAccount(number: 1)
        acc2.save()
        accounts.removeAll()
        accounts.append(contentsOf: [acc1, acc2])
    }
}
