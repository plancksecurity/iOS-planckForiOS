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
}
