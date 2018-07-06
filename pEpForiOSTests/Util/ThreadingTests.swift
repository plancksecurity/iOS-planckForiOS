//
//  ThreadingTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 06.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ThreadingTests: CoreDataDrivenTestBase {
    var account: Account!
    var inbox: Folder!
    var topMessages = [Message]()

    // MARK: - setup/teardown

    override func setUp() {
        super.setUp()

        account = cdAccount.account()

        inbox = Folder.init(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()

        let trash = Folder.init(name: "Trash", parent: nil, account: account, folderType: .trash)
        trash.save()

        topMessages.removeAll()

        for i in 1...EmailListViewModel_ThreadingTests.numberOfTopMessages {
            let msg = TestUtil.createMessage(uid: i, inFolder: inbox)
            topMessages.append(msg)
            msg.save()
        }
    }

    // MARK: - Tests

    func testNoThreads() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        let threaded = inbox.threadAware()
        XCTAssertEqual(threaded.allMessages().count, topMessages.count)

        for msg in topMessages {
            XCTAssertEqual(threaded.messagesInThread(message: msg).count, 0)
        }
    }
}
