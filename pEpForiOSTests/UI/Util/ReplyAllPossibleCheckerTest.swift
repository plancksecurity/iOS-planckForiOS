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

    var currentMessageNumber = 0

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
        test(folder: inbox,
             from: externalFrom1,
             to: [account.user],
             cc: [],
             bcc: [],
             expectedReplyAllPossible: false)

        test(folder: inbox,
             from: externalFrom1,
             to: [account.user, otherRecipient1],
             cc: [],
             bcc: [],
             expectedReplyAllPossible: true)
    }

    // MARK: Helpers

    func test(
        folder: Folder,
        from: Identity, to: [Identity], cc: [Identity], bcc: [Identity],
        expectedReplyAllPossible: Bool) {
        let msgNumber = nextMessageNumber()

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
                          "expected to be able to reply-all on \(msg)")
        } else {
            XCTAssertFalse(replyAllChecker.isReplyAllPossible(forMessage: msg),
                           "did not expect to be able to reply-all on \(msg)")
        }
    }

    func nextMessageNumber() -> Int {
        currentMessageNumber += 1
        return currentMessageNumber
    }
}
