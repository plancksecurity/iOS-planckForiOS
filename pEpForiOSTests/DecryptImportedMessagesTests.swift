//
//  DecryptImportedMessagesTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 08.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class DecryptImportedMessagesTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    var session: PEPSession {
        return PEPSession()
    }
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())

        persistentSetup = PersistentSetup()

        self.backgroundQueue = OperationQueue()
    }

    override func tearDown() {
        persistentSetup = nil
        backgroundQueue.cancelAllOperations()
        backgroundQueue = nil
        PEPSession.cleanup()
        super.tearDown()
    }

    func createLocalAccount(ownUserName: String, ownUserID: String, ownEmailAddress: String) {
        let cdMyAccount = TestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.userName = ownUserName
        cdMyAccount.identity?.userID = ownUserID
        cdMyAccount.identity?.address = ownEmailAddress

        let cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdMyAccount

        TestUtil.skipValidation()
        Record.saveAndWait()
    }
}
