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
    }

    // MARK: - Tests

    func testSetup() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())

        createSomeMessages()

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

        createSomeMessages()

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

        createSomeMessages()

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

    func testSpecialThread() {
        let msgs = createSpecialThread()

        let threaded = inbox.threadAware()
        let topMessages = threaded.allMessages()
        XCTAssertEqual(topMessages.count, 1)

        guard let topMsg = topMessages.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(topMsg, msgs[0])
    }

    // MARK: - Helpers

    func message(by uid: UInt) -> Message {
        return Message.by(messageID: "\(uid)").first!
    }

    func createSomeMessages() {
        topMessages.removeAll()

        for i in 1...inboxCount {
            let msg = TestUtil.createMessage(uid: i, inFolder: inbox)
            topMessages.append(msg)
            msg.save()
        }
    }

    func createSpecialThread() -> [Message] {
        let from1 = Identity.create(address: "ar")
        from1.save()

        let from2 = Identity.create(address: "ba")
        from2.save()

        let from3 = Identity.create(address: "be")
        from3.save()

        let msg1 = Message(uuid: "AB9FF83B-54E9-4F5C-9B0C-C19E96BBD6D6",
                          uid: 1,
                          parentFolder: inbox)
        msg1.from = from1
        msg1.to = [account.user]
        msg1.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        msg1.received = Date.init(timeIntervalSince1970: 1)
        msg1.sent = msg1.received
        msg1.references = ["C4E6FF74-95D7-4058-A96E-68896A0BF25C",
                           "CFF40637-A977-4EA5-8637-2417FBD6E30A",
                           "FB693878-CF66-4985-96C5-DCE469698916",
                           "CACL5pUvx9C45CxDUEgSRbVKgwb08GA58524wPiNBJLrftwJ1YQ",
                           "B8A172B5-8EB2-4A20-913E-428482C79BED",
                           "B262F646-6A0A-4785-ADBC-44C0BCD3AE10",
                           "CACL5pUvKBRSeMpro30GuPXD9RWFwpg7DJWn3+t4ihcAZY0dKDw",
                           "CAGLLa-Uy9kUbNV2-R-fbxkbs2khhQoiXRQc_P-zf1g4rswAOgw"]
        msg1.save()

        let msg2 = Message(uuid: "CAGLLa-UDqi-F=J_5oWvAuHvBzE_YwEwWce3dAorzLRn8w+fPtw",
                           uid: 2,
                           parentFolder: inbox)
        msg2.from = from2
        msg2.to = [account.user]
        msg2.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        msg2.received = Date.init(timeIntervalSince1970: 2)
        msg2.sent = msg2.received
        msg2.references = ["C4E6FF74-95D7-4058-A96E-68896A0BF25C",
                           "CFF40637-A977-4EA5-8637-2417FBD6E30A",
                           "FB693878-CF66-4985-96C5-DCE469698916",
                           "CACL5pUvx9C45CxDUEgSRbVKgwb08GA58524wPiNBJLrftwJ1YQ",
                           "B8A172B5-8EB2-4A20-913E-428482C79BED",
                           "B262F646-6A0A-4785-ADBC-44C0BCD3AE10",
                           "CACL5pUvKBRSeMpro30GuPXD9RWFwpg7DJWn3+t4ihcAZY0dKDw",
                           "CAGLLa-Uy9kUbNV2-R-fbxkbs2khhQoiXRQc_P-zf1g4rswAOgw",
                           "AB9FF83B-54E9-4F5C-9B0C-C19E96BBD6D6"]
        msg2.save()

        let msg3 = Message(uuid: "1862FFC3-F1C3-4F36-953B-42ADB89F333F",
                           uid: 3,
                           parentFolder: inbox)
        msg3.from = from3
        msg3.to = [account.user]
        msg3.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        msg3.received = Date.init(timeIntervalSince1970: 3)
        msg3.sent = msg3.received
        msg3.references = ["CACL5pUvKBRSeMpro30GuPXD9RWFwpg7DJWn3+t4ihcAZY0dKDw",
                           "C4E6FF74-95D7-4058-A96E-68896A0BF25C",
                           "CFF40637-A977-4EA5-8637-2417FBD6E30A",
                           "FB693878-CF66-4985-96C5-DCE469698916",
                           "CACL5pUvx9C45CxDUEgSRbVKgwb08GA58524wPiNBJLrftwJ1YQ",
                           "B8A172B5-8EB2-4A20-913E-428482C79BED",
                           "B262F646-6A0A-4785-ADBC-44C0BCD3AE10",
                           "CACL5pUvKBRSeMpro30GuPXD9RWFwpg7DJWn3+t4ihcAZY0dKDw"]
        msg3.save()

        return [msg1, msg2, msg3]
    }
}
