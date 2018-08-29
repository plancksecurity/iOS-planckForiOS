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
        let msg1 = Message.init(uuid: "1", uid: 1, parentFolder: inbox)
        msg1.from = externalFrom1
        msg1.to = [account.user]
        XCTAssertFalse(replyAllChecker.isReplyAllPossible(forMessage: msg1))

        let msg2 = Message.init(uuid: "2", uid: 2, parentFolder: inbox)
        msg2.from = externalFrom1
        msg2.to = [account.user]
        msg2.cc = [otherRecipient1]
        XCTAssertTrue(replyAllChecker.isReplyAllPossible(forMessage: msg2))
    }
}
