//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class NetworkServiceTests: XCTestCase {
    
    var persistenceSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        
        persistenceSetup = PersistentSetup()
    }
    
    override func tearDown() {
        persistenceSetup = nil
    }

    class NetworkServiceObserver: NetworkServiceDelegate {
        let expSingleAccountSynced: XCTestExpectation?
        var expCanceled: XCTestExpectation?
        var accountInfo: AccountConnectInfo?

        init(expAccountsSynced: XCTestExpectation? = nil, expCanceled: XCTestExpectation? = nil) {
            self.expSingleAccountSynced = expAccountsSynced
            self.expCanceled = expCanceled
        }

        func didSync(service: NetworkService, accountInfo: AccountConnectInfo) {
            if self.accountInfo == nil {
                self.accountInfo = accountInfo
                expSingleAccountSynced?.fulfill()
            }
        }

        func didCancel(service: NetworkService) {
            expCanceled?.fulfill()
        }
    }

    func testSyncOneTime() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))

        let networkService = NetworkService(parentName: #function)
        networkService.networkServiceDelegate = del

        _ = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        networkService.cancel()
        XCTAssertNotNil(del.accountInfo)
        XCTAssertNotNil(CdFolder.all())
        XCTAssertNotNil(CdMessage.all())
    }

    func testCancelSync() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"),
            expCanceled: expectation(description: "expCanceled"))

        let networkService = NetworkService(parentName: #function)
        networkService.networkServiceDelegate = del

        _ = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()
        networkService.cancel()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())
    }

    class SendLayerObserver: SendLayerDelegate {
        let expAccountVerified: XCTestExpectation?

        init(expAccountVerified: XCTestExpectation? = nil) {
            self.expAccountVerified = expAccountVerified
        }

        func didVerify(cdAccount: CdAccount, error: NSError?) {
            XCTAssertNil(error)
            expAccountVerified?.fulfill()
        }

        func newMessage(cdMessage: CdMessage) {
            XCTFail()
        }

        func didRemove(cdFolder: CdFolder) {
            XCTFail()
        }

        func didRemove(cdMessage: CdMessage) {
            XCTFail()
        }
    }

    func testCdAccountVerification() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        let networkService = NetworkService(parentName: #function)
        networkService.networkServiceDelegate = del

        let expAccountVerified = expectation(description: "expAccountVerified")
        let sendLayerDelegate = SendLayerObserver(expAccountVerified: expAccountVerified)
        networkService.sendLayerDelegate = sendLayerDelegate

        let cdAccount = TestData().createWorkingCdAccount()
        Record.saveAndWait()

        XCTAssertTrue(cdAccount.needsVerification)
        guard let creds = cdAccount.credentials?.array as? [CdServerCredentials] else {
            XCTFail()
            return
        }
        for cr in creds {
            XCTAssertTrue(cr.needsVerification)
        }

        networkService.verify(cdAccount: cdAccount)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNotNil(CdFolder.all())
        XCTAssertNotNil(CdMessage.all())

        Record.Context.default.refresh(cdAccount, mergeChanges: true)
        XCTAssertFalse(cdAccount.needsVerification)
        for cr in creds {
            Record.Context.default.refresh(cr, mergeChanges: true)
            XCTAssertFalse(cr.needsVerification)
        }

        del.expCanceled = expectation(description: "expCanceled")
        networkService.cancel()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    class AccountObserver: AccountDelegate {
        let expAccountVerified: XCTestExpectation?
        var account: Account?

        init(expAccountVerified: XCTestExpectation?) {
            self.expAccountVerified = expAccountVerified
        }

        func didVerify(account: Account, error: NSError?) {
            XCTAssertNil(error)
            expAccountVerified?.fulfill()
            self.account = account
        }
    }

    func testAccountVerification() {
        XCTAssertTrue(Account.all().isEmpty)

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        let networkService = NetworkService(parentName: #function)
        networkService.networkServiceDelegate = del

        CdAccount.sendLayer = networkService

        let accountObserver = AccountObserver(
            expAccountVerified: expectation(description: "expAccountVerified"))
        MessageModelConfig.accountDelegate = accountObserver

        let account = TestData().createWorkingAccount()

        XCTAssertTrue(account.needsVerification)
        for cr in account.serverCredentials {
            XCTAssertTrue(cr.needsVerification)
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let verifiedAccount = accountObserver.account else {
            XCTFail()
            return
        }

        XCTAssertFalse(verifiedAccount.needsVerification)
        for cr in verifiedAccount.serverCredentials {
            XCTAssertFalse(cr.needsVerification)
        }

        XCTAssertFalse(verifiedAccount.rootFolders.isEmpty)
        let inbox = verifiedAccount.inbox()
        XCTAssertNotNil(inbox)
        if let inb = inbox {
            XCTAssertGreaterThan(inb.messageCount(), 0)
        }

        del.expCanceled = expectation(description: "expCanceled")
        networkService.cancel()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
