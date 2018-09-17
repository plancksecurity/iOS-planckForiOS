//
//  ReplyUtilTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 05.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ReplyUtilTests: XCTestCase {

    func testReplies() {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name", isMySelf: true)
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let msg = Message(uuid: "001", uid: 1, parentFolder: folder)
        let subject = "This is a subject"
        let expectedReplySubject = "Re: \(subject)"

        var theSubject = subject
        for _ in 1...5 {
            theSubject = " Re:  \(theSubject)"
            msg.shortMessage = theSubject
            XCTAssertEqual(ReplyUtil.replySubject(message: msg), expectedReplySubject)
        }
    }
}
