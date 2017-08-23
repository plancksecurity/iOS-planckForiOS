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
    let connectionManager = ConnectionManager()
    var cdAccount: CdAccount!
    var persistentSetup: PersistentSetup!

    var imapConnectInfo: EmailConnectInfo!
    var smtpConnectInfo: EmailConnectInfo!
    var imapSyncData: ImapSyncData!

    var session = PEPSessionCreator.shared.newSession()

    override func setUp() {
        super.setUp()

        session = PEPSessionCreator.shared.newSession()
        
        persistentSetup = PersistentSetup()
        
        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        imapConnectInfo = cdAccount.imapConnectInfo
        smtpConnectInfo = cdAccount.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)

        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
    }

    override func tearDown() {
        imapSyncData?.sync?.close()

        persistentSetup = nil
        super.tearDown()
    }

    // MARK: - HELPER

    func fetchMessages(parentName: String) {
        let expMailsPrefetched = expectation(description: "expMailsPrefetched")

        let opLogin = LoginImapOperation(parentName: parentName, imapSyncData: imapSyncData)
        let op = FetchMessagesOperation(parentName: parentName, imapSyncData: imapSyncData,
                                        folderName: ImapSync.defaultImapInboxName)
        op.addDependency(opLogin)
        op.completionBlock = {
            op.completionBlock = nil
            expMailsPrefetched.fulfill()
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
