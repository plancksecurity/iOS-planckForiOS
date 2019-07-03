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
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework

open class CoreDataDrivenTestBase: XCTestCase {
    var moc : NSManagedObjectContext!

    var account: Account {
        return Account(cdObject: cdAccount, context: moc)
    }
    var cdAccount: CdAccount!

    public var imapConnectInfo: EmailConnectInfo!
    public var smtpConnectInfo: EmailConnectInfo!
    public var imapSyncData: ImapSyncData!

    var session: PEPSession {
        return PEPSession()
    }

    override open func setUp() {
        super.setUp()
        moc = Stack.shared.mainContext

        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)
        moc.saveAndLogErrors()
        self.cdAccount = cdAccount

        imapConnectInfo = cdAccount.imapConnectInfo
        smtpConnectInfo = cdAccount.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)

        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
    }

    override open func tearDown() {
        imapSyncData?.sync?.close()
        Stack.shared.reset()
        PEPSession.cleanup()
        XCTAssertTrue(PEPUtil.pEpClean())
        super.tearDown()
    }

    // MARK: - HELPER

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
