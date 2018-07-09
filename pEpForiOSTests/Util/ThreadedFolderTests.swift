//
//  ThreadedFolderTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 06.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ThreadedFolderTests: CoreDataDrivenTestBase {
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

    func testSetup() {
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

    func testTopMessageReferencingOtherTopMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())

        let firstDisplayedMessage = message(by: UInt(inboxCount))
        let secondDisplayedMessage = message(by: UInt(inboxCount - 1))
        secondDisplayedMessage.references = [firstDisplayedMessage.messageID]
        secondDisplayedMessage.save()

        let threaded = inbox.threadAware()
        let inboxMessages = threaded.allMessages()
        XCTAssertEqual(inboxMessages.count, topMessages.count - 1)

        for msg in inboxMessages {
            if msg == firstDisplayedMessage {
                XCTAssertEqual(threaded.messagesInThread(message: msg).count, 2)
            } else {
                XCTAssertEqual(threaded.messagesInThread(message: msg).count, 0)
            }
        }
    }

    func testSiblingsByReferencingSentMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())

        let lastInboxUid = TestUtil.highestUid()

        let sentFolder = Folder.init(name: "Sent",
                                     parent: nil,
                                     account: account,
                                     folderType: .sent)
        sentFolder.save()

        let sentMsg = TestUtil.createMessage(uid: TestUtil.nextUid(), inFolder: sentFolder)
        sentMsg.save()

        let firstDisplayedMessage = message(by: UInt(lastInboxUid))
        firstDisplayedMessage.references = [sentMsg.messageID]
        firstDisplayedMessage.save()

        let secondDisplayedMessage = message(by: UInt(lastInboxUid - 1))
        secondDisplayedMessage.references = [sentMsg.messageID]
        secondDisplayedMessage.save()

        let threaded = inbox.threadAware()
        let inboxMessageSet = Set(threaded.allMessages())
        XCTAssertEqual(inboxMessageSet.count, topMessages.count - 1)

        XCTAssertEqual(threaded.messagesInThread(message: firstDisplayedMessage).count, 3)
        XCTAssertEqual(threaded.messagesInThread(message: secondDisplayedMessage).count, 3)

        XCTAssertTrue(inboxMessageSet.contains(firstDisplayedMessage))
        XCTAssertFalse(inboxMessageSet.contains(secondDisplayedMessage))

        for msg in inboxMessageSet {
            if msg == firstDisplayedMessage {
                XCTAssertEqual(threaded.messagesInThread(message: msg).count, 3)
            } else {
                XCTAssertEqual(threaded.messagesInThread(message: msg).count, 0)
            }
        }

        let messageThreadSet1 = Set(firstDisplayedMessage.messagesInThread())
        XCTAssertTrue(messageThreadSet1.contains(firstDisplayedMessage))
        XCTAssertTrue(messageThreadSet1.contains(secondDisplayedMessage))
        XCTAssertTrue(messageThreadSet1.contains(sentMsg))
    }

    // MARK: - Helpers

    func message(by uid: UInt) -> Message {
        return Message.by(messageID: "\(uid)").first!
    }

}
