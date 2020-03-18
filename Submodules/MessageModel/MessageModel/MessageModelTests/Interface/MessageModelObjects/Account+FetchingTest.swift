//
//  Account+FetchingTest.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 25/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel

class Acount_FetchingTest: PersistentStoreDrivenTestBase {
    var cdAccount1: CdAccount!
    var cdAccount2: CdAccount!
    var cdAccount3: CdAccount!

    override func setUp() {
        super.setUp()

        //Account 1
        cdAccount1 = TestUtil.createFakeAccount(moc: moc)

        //Account 2
        cdAccount2 = TestUtil.createFakeAccount(idAddress: "account2@test.com",
                                              idUserName: "test2",
                                              moc: moc)

        cdAccount3 = TestUtil.createFakeAccount(idAddress: "account3@test.com",
                                              idUserName: "test3",
                                              moc: moc)
        let account3 = cdAccount3.account()
        account3.imapServer!.automaticallyTrusted = true
        account3.save()

        moc.saveAndLogErrors()
    }

    override func tearDown() {
        cdAccount1 = nil
        cdAccount2 = nil
        super.tearDown()
    }

    func testGetAllAccountsAllowedToManuallyTrust() {
        // Given
        let expectedAllowedAccounts = Set([cdAccount.account(),
                                           cdAccount1.account(),
                                           cdAccount2.account()])
        let expectedAllowedAccountCount = expectedAllowedAccounts.count

        // When
        let allowedAccounts = Set(Account.Fetch.allAccountsAllowedToManuallyTrust())

        // Then
        XCTAssertEqual(allowedAccounts.count, expectedAllowedAccountCount)
        XCTAssertEqual(allowedAccounts, expectedAllowedAccounts)
    }

    func testGetAccountByAddres() {
        // Given
        let address1 = cdAccount1.account().user.address
        let address2 = cdAccount2.account().user.address
        let address3 = cdAccount3.account().user.address

        // When
        let account1 = Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address1)
        let account2 = Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address2)
        let account3 = Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address3)

        // Then
        XCTAssertEqual(cdAccount1.account(), account1)
        XCTAssertEqual(cdAccount2.account(), account2)
        XCTAssertEqual(cdAccount3.account(), account3)
        XCTAssertNotEqual(cdAccount3.account(), account1)
    }
}
