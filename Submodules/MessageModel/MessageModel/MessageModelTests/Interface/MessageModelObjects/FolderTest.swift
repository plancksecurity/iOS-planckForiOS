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

    //Test for regular folder
    func testCountUnreads() {
        let localInbox = TestUtil.createFolder(name: "inbox", folderType: .inbox, moc: moc)
        localInbox.account = cdAccount
        let m = TestUtil.createCdMessage(withText: "a", sentDate: nil, cdFolder: localInbox, moc: moc)
        m.imap = CdImapFields(context: moc)
        let localFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = localFlags
        let serverFlags = CdImapFlags(context: moc)
        m.imap?.serverFlags = serverFlags
        m.imap?.localFlags?.flagSeen = false
        m.uid = 1
        m.pEpRating = 3

        //Create another mail, this has been "seen" to be sure the filter works.
        let m2 = TestUtil.createCdMessage(withText: "a", sentDate: nil, cdFolder: localInbox, moc: moc)
        m2.imap = CdImapFields(context: moc)
        m2.imap?.localFlags = CdImapFlags(context: moc)
        m2.imap?.serverFlags = CdImapFlags(context: moc)

        m2.imap?.localFlags?.flagSeen = true

        m2.uid = 2
        m2.pEpRating = 3

        moc.saveAndLogErrors()

        let result = localInbox.folder().countUnread
        XCTAssertEqual(result, 1)

    }

    //Test for UnifiedInbox
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
        m.uid = 1
        m.pEpRating = 3

        //Create another mail, this has been "seen" to be sure the filter works.
        let m2 = TestUtil.createCdMessage(withText: "a", sentDate: nil, cdFolder: localInbox, moc: moc)
        m2.imap = CdImapFields(context: moc)
        m2.imap?.localFlags = CdImapFlags(context: moc)
        m2.imap?.serverFlags = CdImapFlags(context: moc)

        m2.imap?.localFlags?.flagSeen = true

        m2.uid = 2
        m2.pEpRating = 3

        moc.saveAndLogErrors()
        let result = Folder.countAllUnread(folderType: .inbox)
        XCTAssertEqual(result, 1)
     }
}
