//
//  FolderTest.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 11/06/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel


class FolderTest: PersistentStoreDrivenTestBase {
    var outbox : Folder!

    override func setUp() {
        super.setUp()

        let localOutbox = TestUtil.createFolder(name: "outbox", folderType: .outbox, moc: moc)
        localOutbox.account = cdAccount
        outbox = localOutbox.folder()


        moc.saveAndLogErrors()
    }
    
    func testOutgoingMessagesShownInOutbox() {
        var numberOfExpectedMessages = 0
        let predicate = outbox.messagesPredicate
        XCTAssertEqual(nil, CdMessage.all(predicate: predicate, in: moc)?.count)
        numberOfExpectedMessages = 1
        _ = TestUtil.createCdMessage(cdFolder: outbox.cdFolder()! , moc: moc)
        moc.saveAndLogErrors()
        XCTAssertEqual(numberOfExpectedMessages,
                       CdMessage.all(predicate: predicate, in: moc)?.count)

    }

    func testCountUnreads() {
        let inbox = TestUtil.createFolder(name: "inbox", folderType: .inbox, moc: moc)
        inbox.account = cdAccount
        let inboxFolder = inbox.folder()
        let message = TestUtil.createCdMessage(cdFolder: inboxFolder.cdFolder()! , moc: moc)
        XCTAssert(inboxFolder.countUnread == 0)
        message.imap = CdImapFields(context: moc)
        message.imap?.localFlags = CdImapFlags(context: moc)
        message.imap?.localFlags?.flagSeen = false
        XCTAssert(inboxFolder.countUnread == 1)
    }

    func testAllCountUnreads() {
        let localInbox = TestUtil.createFolder(name: "inbox", folderType: .inbox, moc: moc)
        localInbox.account = cdAccount

        let m = TestUtil.createCdMessage(withText: "a", sentDate: nil, cdFolder: localInbox, moc: moc)
        m.imap = CdImapFields(context: moc)

        let localFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = localFlags

        let serverFlags = CdImapFlags(context: moc)
        m.imap?.serverFlags = serverFlags

        m.imap?.localFlags?.flagSeen = false
        moc.saveAndLogErrors()

        let result = Folder.countUnread(folderType: .inbox)
        XCTAssertEqual(result, 1)
     }
}
