//
//  AccountQueryResultTest.swift
//  MessageModelTests
//
//  Created by Martin Brude on 31/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import XCTest
import CoreData
@testable import MessageModel

class AccountQueryResultTest: PersistentStoreDrivenTestBase {
    var account1: CdAccount!
    var account2: CdAccount!
    var accountQueryResults: AccountQueryResults!
    var queryResultIPRDelegate : QueryResultsIndexPathRowDelegate?

    override func setUp() {
        super.setUp()
        account1 = cdAccount
        queryResultIPRDelegate = MockRowDelegate()
        accountQueryResults = AccountQueryResults(rowDelegate: queryResultIPRDelegate)
        XCTAssertNoThrow(try accountQueryResults?.startMonitoring())

        account2 = TestUtil.createFakeAccount(idAddress: "account2@test.com",
                                              idUserName: "test2",
                                              moc: moc)
        moc.saveAndLogErrors()
    }

    func testAll() {
        XCTAssert(accountQueryResults.all.count == 2)
    }

    func testCount() {
        XCTAssert(accountQueryResults.count == 2)
    }

    func testSubscript() {
        XCTAssert(accountQueryResults.all.contains(account2.account()))
        XCTAssert(accountQueryResults.all.contains(account1.account()))
    }

    func testRowDelegateNotNil() {
        XCTAssertNotNil(accountQueryResults?.rowDelegate)
    }

    func testStartMonitoring() {
        // Given
        let secondDelegate = MockRowDelegate()
        let secondAccountQueryResults = AccountQueryResults(rowDelegate: secondDelegate)
        // When
        guard let _ = try? secondAccountQueryResults.startMonitoring() else {
            XCTFail()
            return
        }
        // Then
        let expectedMessagesCount = 2
        XCTAssertEqual(secondAccountQueryResults.count, expectedMessagesCount)
    }

    func testDidInsert() {
        let exp = expectation(description: "delegate called for didInsert")
        let delegateTest = MockRowDelegate(withExp: exp, expType: .didInsert)
        accountQueryResults.rowDelegate = delegateTest
        try? accountQueryResults.startMonitoring()
        
        _ = TestUtil.createFakeAccount(idAddress: "account3@test.com",
                                                  idUserName: "test3",
                                                  moc: moc)
        moc.saveAndLogErrors()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testDidDelete() {
        let exp = expectation(description: "delegate called for didDelete")
        let delegateTest = MockRowDelegate(withExp: exp, expType: .didDelete)
        accountQueryResults.rowDelegate = delegateTest
        try? accountQueryResults.startMonitoring()

        _ = TestUtil.createFakeAccount(idAddress: "testDidDelete@test.com",
                                                  idUserName: "testDidDelete",
                                                  moc: moc)

        accountQueryResults.all.last?.delete()
        moc.saveAndLogErrors()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testDidChange() {
        let exp = expectation(description: "delegate called for didChange")
        let delegateTest = MockRowDelegate(withExp: exp, expType: .didChange)
        accountQueryResults.rowDelegate = delegateTest
        try? accountQueryResults.startMonitoring()

        _ = TestUtil.createFakeAccount(idAddress: "testDidChange@test.com",
                                                  idUserName: "testDidChange",
                                                  moc: moc)

        accountQueryResults.all.last?.user.address = "change@ddress.com"
        moc.saveAndLogErrors()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testWillChange() {
        let exp = expectation(description: "delegate called for willChange")
        let delegateTest = MockRowDelegate(withExp: exp, expType: .willChange)
        accountQueryResults.rowDelegate = delegateTest
        try? accountQueryResults.startMonitoring()
        _ = TestUtil.createFakeAccount(idAddress: "testWillChange@test.com",
                                                  idUserName: "testWillChange",
                                                  moc: moc)

        accountQueryResults.all.last?.user.address = "change@ddress.com"
        moc.saveAndLogErrors()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

class MockRowDelegate: QueryResultsIndexPathRowDelegate {
    let exp: XCTestExpectation?
    let expType: expectationType?

    enum expectationType {
        case didInsert, didUpdate, didDelete, didMove, willChange, didChange, none
    }

    init(withExp exp: XCTestExpectation? = nil, expType: expectationType? = nil) {
        self.exp = exp
        self.expType = expType
    }

    func didInsertRow(indexPath: IndexPath) {
        if expType == .didInsert {
            exp?.fulfill()
        }
    }

    func didUpdateRow(indexPath: IndexPath) {
        if expType == .didUpdate {
            exp?.fulfill()
        }
    }

    func didDeleteRow(indexPath: IndexPath) {
        if expType == .didDelete {
            exp?.fulfill()
        }
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        XCTFail("Should not happen")
    }

    func willChangeResults() {
        if expType == .willChange {
            exp?.fulfill()
        }
    }

    func didChangeResults() {
        if expType == .didChange {
            exp?.fulfill()
        }
    }
}
