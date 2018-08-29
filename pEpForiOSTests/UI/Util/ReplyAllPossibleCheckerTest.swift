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

class ReplyAllPossibleCheckerTest: CoreDataDrivenTestBase {
    var account: Account!
    var inbox: Folder!
    var replyAllChecker = ReplyAllPossibleChecker()

    var externalFrom1 = Identity.create(address: "1@example.com",
                                        userID: "1",
                                        addressBookID: "1",
                                        userName: "user1",
                                        isMySelf: false)

    var otherRecipient1 = Identity.create(address: "2@example.com",
                                          userID: "2",
                                          addressBookID: "2",
                                          userName: "user2",
                                          isMySelf: false)

    var otherRecipient2 = Identity.create(address: "3@example.com",
                                          userID: "3",
                                          addressBookID: "3",
                                          userName: "user3",
                                          isMySelf: false)

    /**
     Maps test name to message counter in that test.
     */
    var currentMessageNumber = [String:Int]()

    override func setUp() {
        super.setUp()

        replyAllChecker = ReplyAllPossibleChecker()

        account = cdAccount.account()

        inbox = Folder(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSimplestCases() {
        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: inbox,
                                        from: externalFrom1,
                                        to: [account.user],
                                        cc: [],
                                        bcc: []))

        XCTAssertTrue(replyAllPossible(testName: #function,
                                       folder: inbox,
                                       from: externalFrom1,
                                       to: [account.user, otherRecipient1],
                                       cc: [],
                                       bcc: []))

        XCTAssertTrue(replyAllPossible(testName: #function,
                                       folder: inbox,
                                       from: externalFrom1,
                                       to: [],
                                       cc: [],
                                       bcc: [account.user, otherRecipient1]))

        // Note: Why would we receive such an email?
        // If that fails, maybe because it doesn't make actual sense.
        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: inbox,
                                        from: externalFrom1,
                                        to: [externalFrom1],
                                        cc: [],
                                        bcc: []))

        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: inbox,
                                        from: account.user,
                                        to: [account.user],
                                        cc: [],
                                        bcc: []))

        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: inbox,
                                        from: account.user,
                                        to: [account.user],
                                        cc: [account.user],
                                        bcc: [account.user]))

        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: inbox,
                                        from: externalFrom1,
                                        to: [account.user, account.user],
                                        cc: [],
                                        bcc: []))

        XCTAssertFalse(replyAllPossible(testName: #function,
                                        folder: inbox,
                                        from: externalFrom1,
                                        to: [account.user, account.user],
                                        cc: [account.user, account.user],
                                        bcc: [account.user, account.user]))

        XCTAssertTrue(replyAllPossible(testName: #function,
                                       folder: inbox,
                                       from: externalFrom1,
                                       to: [account.user],
                                       cc: [],
                                       bcc: [otherRecipient1, otherRecipient2]))
    }

    // MARK: Helpers

    func replyAllPossible(
        testName: String,
        folder: Folder,
        from: Identity, to: [Identity], cc: [Identity], bcc: [Identity]) -> Bool {
        let msgNumber = nextMessageNumber(testName: testName)

        let msg = Message.init(uuid: "\(msgNumber)", uid: UInt(msgNumber), parentFolder: folder)

        msg.from = from

        if !to.isEmpty {
            msg.to = to
        }

        if !cc.isEmpty {
            msg.cc = cc
        }

        if !bcc.isEmpty {
            msg.bcc = bcc
        }

        return replyAllChecker.isReplyAllPossible(forMessage: msg)
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
