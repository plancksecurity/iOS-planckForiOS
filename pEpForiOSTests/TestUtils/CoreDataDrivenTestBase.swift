//
//  CoreDataDrivenTestBase.swift
//  pEpForiOS
//
//  Created by buff on 26.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import CoreData
@testable import pEpForiOS
import MessageModel

class CoreDataDrivenTestBase: XCTestCase {
    var cdAccount: CdAccount!
    var persistentSetup: PersistentSetup!

    var imapConnectInfo: EmailConnectInfo!
    var smtpConnectInfo: EmailConnectInfo!
    var imapSyncData: ImapSyncData!

    var session: PEPSession {
        return PEPSession()
    }

    override func setUp() {
        super.setUp()
        setupEverythingUp()
    }

    override func tearDown() {
        tearEverythingDown()
        super.tearDown()
    }

    // MARK: - HELPER

    func setupEverythingUp() {
        XCTAssertTrue(PEPUtil.pEpClean())

        persistentSetup = PersistentSetup()

        let cdAccount = SecretTestData().createWorkingCdAccount()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        imapConnectInfo = cdAccount.imapConnectInfo
        smtpConnectInfo = cdAccount.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)

        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
    }

    func tearEverythingDown() {
        imapSyncData?.sync?.close()
        persistentSetup = nil
        PEPSession.cleanup()
    }

    func fetchMessages(parentName: String) {
        let expMailsFetched = expectation(description: "expMailsFetched")

        let opLogin = LoginImapOperation(parentName: parentName, imapSyncData: imapSyncData)
        let op = FetchMessagesOperation(parentName: parentName, imapSyncData: imapSyncData,
                                        folderName: ImapSync.defaultImapInboxName)
        op.addDependency(opLogin)
        op.completionBlock = {
            op.completionBlock = nil
            expMailsFetched.fulfill()
        }

        let bgQueue = OperationQueue()
        bgQueue.addOperation(opLogin)
        bgQueue.addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })
    }
}
