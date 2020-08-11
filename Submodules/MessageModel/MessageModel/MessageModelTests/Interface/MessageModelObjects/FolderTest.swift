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
        let outbox = TestUtil.createFolder(name: "outbox", folderType: .outbox, moc: moc)
        let inbox = TestUtil.createFolder(name: "inbox", folderType: .inbox, moc: moc)
        let drafts = TestUtil.createFolder(name: "draft", folderType: .drafts, moc: moc)
        createMessage(isUnread: false, in: inbox)
        createMessage(isUnread: false, in: drafts)
        //Only one unread mail in draft
        createMessage(isUnread: true, in: drafts)
        createMessage(isUnread: true, in: outbox)
        createMessage(isUnread: true, in: outbox)
        createMessage(isUnread: true, in: outbox)
        moc.saveAndLogErrors()

        //Test for regular folder
        let result = drafts.folder().countUnread
        XCTAssertEqual(result, 1)

        //Test for UnifiedInbox
        //Only one unread mail in draft

        XCTAssertEqual(Folder.countUnreadIn(foldersOfType: .inbox), 0)
        XCTAssertEqual(Folder.countUnreadIn(foldersOfType: .drafts), 1)
        XCTAssertEqual(Folder.countUnreadIn(foldersOfType: .outbox), 3)
    }

    private func createMessage(isUnread : Bool, in folder: CdFolder) {
        folder.account = cdAccount
        let m = TestUtil.createCdMessage(withText: "lala", sentDate: nil, cdFolder: folder, moc: moc)
        m.imap = CdImapFields(context: moc)
        let localFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = localFlags
        let serverFlags = CdImapFlags(context: moc)
        m.imap?.serverFlags = serverFlags
        m.imap?.localFlags?.flagSeen = !isUnread
        m.uid = 1
        m.pEpRating = 3
    }
}
