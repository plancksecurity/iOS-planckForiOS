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
        msg.shortMessage = subject
        XCTAssertEqual(ReplyUtil.replySubject(message: msg), "Re: \(subject)")

        for someReplyPrefix in ReplyUtil.replyPrefixes {
            for theReplyPrefix in
                [someReplyPrefix, someReplyPrefix.lowercased(), someReplyPrefix.uppercased()] {
                    // missing ":", not detected
                    let inSubject = "\(theReplyPrefix) \(subject)"
                    let replySubject = "Re: \(inSubject)"
                    msg.shortMessage = inSubject
                    XCTAssertEqual(
                        ReplyUtil.replySubject(message: msg),
                        replySubject,
                        "expected reply to \"\(inSubject)\" to have reply \"\(replySubject)\"")

                    // nothing added, because already counted as a reply
                    let inSubject2 = "\(theReplyPrefix): \(subject)"
                    msg.shortMessage = inSubject2
                    XCTAssertEqual(
                        ReplyUtil.replySubject(message: msg),
                        inSubject2,
                        "expected reply to \"\(inSubject2)\" to stay the same")
            }
        }
    }
}
