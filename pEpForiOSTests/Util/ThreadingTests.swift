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
    var inboxCount = 5

    // MARK: - setup/teardown

    override func setUp() {
        super.setUp()

        account = cdAccount.account()

        inbox = Folder.init(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()

        let trash = Folder.init(name: "Trash", parent: nil, account: account, folderType: .trash)
        trash.save()

        topMessages.removeAll()

        for i in 1...inboxCount {
            let msg = TestUtil.createMessage(uid: i, inFolder: inbox)
            topMessages.append(msg)
            msg.save()
        }
    }

    // MARK: - Tests

    func testSetupThreaded() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        let threaded = inbox.threadAware()
        XCTAssertEqual(threaded.allMessages().count, topMessages.count)

        XCTAssertEqual(topMessages[0].uid, 1)
        let inboxMessages = threaded.allMessages()
        XCTAssertEqual(inboxMessages[0].uid, UInt(inboxCount))

        for msg in topMessages {
            XCTAssertEqual(threaded.messagesInThread(message: msg).count, 0)
        }
    }

    func testThreadedSiblingsByReferencingSentMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())

        let sentFolder = Folder.init(name: "Sent",
                                     parent: nil,
                                     account: account,
                                     folderType: .sent)
        sentFolder.save()

        let sentMsg = TestUtil.createMessage(uid: TestUtil.nextUid(), inFolder: sentFolder)
        sentMsg.save()

        topMessages[0].references = [sentMsg.messageID]
        topMessages[0].save()

        topMessages[1].references = [sentMsg.messageID]
        topMessages[1].save()

        let threaded = inbox.threadAware()
        let inboxMessages = threaded.allMessages()
        XCTAssertEqual(inboxMessages.count, topMessages.count - 1)

        XCTAssertEqual(threaded.messagesInThread(message: inboxMessages[0]).count, 1)
        XCTAssertEqual(threaded.messagesInThread(message: inboxMessages[1]).count, 0)
        XCTAssertEqual(threaded.messagesInThread(message: inboxMessages[2]).count, 0)
    }
}
