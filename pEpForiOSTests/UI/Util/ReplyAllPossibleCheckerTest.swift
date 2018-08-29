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
        test(testName: #function,
             folder: inbox,
             from: externalFrom1,
             to: [account.user],
             cc: [],
             bcc: [],
             expectedReplyAllPossible: false)

        test(testName: #function,
             folder: inbox,
             from: externalFrom1,
             to: [account.user, otherRecipient1],
             cc: [],
             bcc: [],
             expectedReplyAllPossible: true)

        test(testName: #function,
             folder: inbox,
             from: externalFrom1,
             to: [],
             cc: [],
             bcc: [account.user, otherRecipient1],
             expectedReplyAllPossible: true)

        // Note: Why would we receive such an email?
        // If that fails, maybe because it doesn't make actual sense.
        test(testName: #function,
             folder: inbox,
             from: externalFrom1,
             to: [externalFrom1],
             cc: [],
             bcc: [],
             expectedReplyAllPossible: false)
    }

    // MARK: Helpers

    func test(
        testName: String,
        folder: Folder,
        from: Identity, to: [Identity], cc: [Identity], bcc: [Identity],
        expectedReplyAllPossible: Bool) {
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

        if expectedReplyAllPossible {
            XCTAssertTrue(replyAllChecker.isReplyAllPossible(forMessage: msg),
                          "\(testName) expected to be able to reply-all on \(msg)")
        } else {
            XCTAssertFalse(replyAllChecker.isReplyAllPossible(forMessage: msg),
                           "\(testName) did not expect to be able to reply-all on \(msg)")
        }
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
