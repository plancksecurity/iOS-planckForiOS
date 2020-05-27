//
//  ReplyAllPossibleCheckerTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ReplyAllPossibleCheckerTest: AccountDrivenTestBase {
    var inbox: Folder!
    var sent: Folder!
    var draft: Folder!

    var msg: Message!

    var replyAllChecker: ReplyAllPossibleChecker!

    var externalFrom1: Identity!

    var otherRecipient1: Identity!

    var otherRecipient2: Identity!

    /**
     Maps test name to message counter in that test.
     */
    var currentMessageNumber = [String:Int]()

    override func setUp() {
        super.setUp()

        externalFrom1 = Identity(address: "1@example.com",
                                 userID: "1",
                                 addressBookID: "1",
                                 userName: "user1")

        otherRecipient1 = Identity(address: "2@example.com",
                                   userID: "2",
                                   addressBookID: "2",
                                   userName: "user2")

        otherRecipient2 = Identity(address: "3@example.com",
                                   userID: "3",
                                   addressBookID: "3",
                                   userName: "user3")

        inbox = Folder(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.session.commit()

        sent = Folder(name: "the_sent_folder", parent: nil, account: account, folderType: .sent)
        sent.session.commit()

        draft = Folder(name: "DRAFTS", parent: nil, account: account, folderType: .drafts)
        draft.session.commit()

        let msg = Message.init(uuid: "\(666)", uid: 666, parentFolder: inbox)

        replyAllChecker = ReplyAllPossibleChecker(messageToReplyTo: msg)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSimpleInboxCases() {
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [account.user],
                             cc: [],
                             bcc: []))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [account.user, otherRecipient1],
                             cc: [],
                             bcc: []))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [],
                             cc: [],
                             bcc: [account.user, otherRecipient1]))

        // Fake
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [externalFrom1],
                             cc: [],
                             bcc: []))

        // Some SPAM?
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [],
                             cc: [],
                             bcc: []))

        // .fullyAnonymous?
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: account.user,
                             to: [account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: account.user,
                             to: [account.user],
                             cc: [account.user],
                             bcc: [account.user]))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [account.user, account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [account.user, account.user],
                             cc: [account.user, account.user],
                             bcc: [account.user, account.user]))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: externalFrom1,
                             to: [account.user],
                             cc: [],
                             bcc: [otherRecipient1, otherRecipient2]))
    }

    func testSimpleSentCases() {
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: account.user,
                             to: [otherRecipient1],
                             cc: [],
                             bcc: []))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: account.user,
                             to: [otherRecipient1, otherRecipient2],
                             cc: [],
                             bcc: []))

        // A message from someone else that was moved into sent.
        // But only 1 recipient.
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: externalFrom1,
                             to: [otherRecipient1],
                             cc: [],
                             bcc: []))

        // A message from someone else that was moved into sent.
        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: externalFrom1,
                             to: [otherRecipient1, otherRecipient2],
                             cc: [],
                             bcc: []))
    }

    func testSentWithoutFrom() {
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: nil,
                             to: [otherRecipient1],
                             cc: [],
                             bcc: []))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: nil,
                             to: [otherRecipient1, otherRecipient2],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: nil,
                             to: [otherRecipient1],
                             cc: [],
                             bcc: []))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: sent,
                             from: nil,
                             to: [otherRecipient1, otherRecipient2],
                             cc: [],
                             bcc: []))
    }

    func testInboxWithoutFrom() {
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user, otherRecipient1],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [],
                             cc: [],
                             bcc: [account.user, otherRecipient1]))

        // Fake
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [externalFrom1],
                             cc: [],
                             bcc: []))

        // Some SPAM?
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [],
                             cc: [],
                             bcc: []))

        // .fullyAnonymous?
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user],
                             cc: [account.user],
                             bcc: [account.user]))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user, account.user],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user, account.user],
                             cc: [account.user, account.user],
                             bcc: [account.user, account.user]))

        XCTAssertTrue(
            replyAllPossible(testName: #function,
                             folder: inbox,
                             from: nil,
                             to: [account.user],
                             cc: [],
                             bcc: [otherRecipient1, otherRecipient2]))
    }

    func testDrafts() {
        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: draft,
                             from: account.user,
                             to: [otherRecipient1],
                             cc: [],
                             bcc: []))

        XCTAssertFalse(
            replyAllPossible(testName: #function,
                             folder: draft,
                             from: account.user,
                             to: [otherRecipient1, otherRecipient2],
                             cc: [],
                             bcc: []))

        // strange to land in drafts, but can happen (accidental move etc.)
        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: draft,
                                        from: externalFrom1,
                                        to: [otherRecipient1, otherRecipient2],
                                        cc: [],
                                        bcc: []))
    }

    // MARK: Helpers

    func replyAllPossible(testName: String,
                          folder: Folder,
                          from: Identity?,
                          to: [Identity],
                          cc: [Identity],
                          bcc: [Identity]) -> Bool {
        let msgNumber = nextMessageNumber(testName: testName)
        msg = Message.init(uuid: "\(msgNumber)", uid: msgNumber, parentFolder: folder)
        msg.from = from
        replyAllChecker = ReplyAllPossibleChecker(messageToReplyTo: msg)
        if !to.isEmpty {
            msg.replaceTo(with: to)
        }

        if !cc.isEmpty {
            msg.replaceCc(with: cc)
        }

        if !bcc.isEmpty {
            msg.replaceBcc(with: bcc)
        }

        return replyAllChecker.isReplyAllPossible()
    }

    func nextMessageNumber(testName: String) -> Int {
        if var currentCount = currentMessageNumber[testName] {
            currentCount += 1
            currentMessageNumber[testName] = currentCount
            return currentCount
        } else {
            currentMessageNumber[testName] = 1
            return 1
        }
    }
    
}
