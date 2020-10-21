//
//  PersistentStoreDrivenTestBase.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.08.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
import PEPObjCAdapterFramework

@testable import MessageModel

class PersistentStoreDrivenTestBase: XCTestCase {
    var moc: NSManagedObjectContext!
    @available(*, deprecated,
    message: "You must not use this! It only exists to support old tests moved from app target tests")
    var account: Account {
        return MessageModelObjectUtils.getAccount(fromCdAccount: cdAccount)
    }
    var cdAccount: CdAccount!
    var cdInbox: CdFolder!

    var imapConnectInfo: EmailConnectInfo!
    var smtpConnectInfo: EmailConnectInfo!
    var imapConnection: ImapConnection!

    override func setUp() {
        super.setUp()
        Stack.shared.reset() //!!!: this should not be required. Rm after all tests use a propper base class!
        moc = Stack.shared.mainContext
        cdAccount = SecretTestData().createWorkingCdAccount()

        cdInbox = TestUtil.createFolder(moc: moc)
        cdInbox.account = cdAccount

        // NOTE: Must be saved before the various connect infos grab the `objectID`.
        // Order is important here.
        moc.saveAndLogErrors()

        imapConnectInfo = cdAccount.imapConnectInfo
        smtpConnectInfo = cdAccount.smtpConnectInfo
        imapConnection = ImapConnection(connectInfo: imapConnectInfo)
    }

    override func tearDown() {
        Stack.shared.reset()
        PEPSession.cleanup()
        XCTAssertTrue(PEPUtils.pEpClean())
        super.tearDown()
    }
}
