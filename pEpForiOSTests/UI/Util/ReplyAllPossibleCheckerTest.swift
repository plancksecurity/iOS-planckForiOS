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
    
    func testSimplestMail() {
        let msg = Message.init(uuid: "1", uid: 1, parentFolder: inbox)
        msg.from = Identity.create(address: "1@example.com",
                                   userID: "1",
                                   addressBookID: "1",
                                   userName: "user1",
                                   isMySelf: false)
        msg.to = [account.user]

        XCTAssertFalse(replyAllChecker.isReplyAllPossible(forMessage: msg))
    }
}
