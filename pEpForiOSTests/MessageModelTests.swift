//
//  MessageModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//


import MessageModel

import XCTest

class MessageModelTests: XCTestCase {
    let waitTime = TestUtil.modelSaveWaitTime
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    /*
    func testFolderLookUp() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        Folder.create(name: "inbox").folderType = .inbox
        Folder.create(name: "sent").folderType = .sent
        Folder.create(name: "drafts").folderType = .drafts

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertFalse(Folder.by(folderType: FolderType.inbox).isEmpty)
        XCTAssertFalse(Folder.by(folderType: FolderType.sent).isEmpty)
        XCTAssertFalse(Folder.by(folderType: FolderType.drafts).isEmpty)
    }
     */

    func testAccountSave() {
        CdAccount.sendLayer = DefaultSendLayer()

        // setup AccountDelegate
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        let _ = TestData().createWorkingAccount()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(accountDelegate.error)
        })
    }

    func testExistingUserID() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        let cdIdent = CdIdentity.create()
        cdIdent.address = "whatever@example.com"
        cdIdent.userID = "userID1"

        let ident = Identity.create(address: cdIdent.address!)
        ident.userID = "userID2"

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let idIdent2 = CdIdentity.first(with: "address", value: cdIdent.address!)
        XCTAssertEqual(idIdent2?.userID, cdIdent.userID)
    }

    func testSaveTrustedServer() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        let _ = Server.create(serverType: .imap, port: 4096, address: "what",
                              transport: .tls, trusted: true)

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let cdServer = CdServer.first() else {
            XCTFail()
            return
        }
        XCTAssertTrue(cdServer.trusted)
    }

    func testSaveTrustedConnectInfo() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        let ident = Identity.create(address: "address")
        let server = Server.create(serverType: .imap, port: 4096, address: "what",
                                   transport: .tls, trusted: true)
        let cred = ServerCredentials.create(userName: "what", servers: [server])
        let _ = Account.create(identity: ident, credentials: [cred])

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let cdAccount = CdAccount.first() else {
            XCTFail()
            return
        }
        guard let ci = cdAccount.imapConnectInfo else {
            XCTFail()
            return
        }
        XCTAssertTrue(ci.trusted)
    }
}
