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
}
