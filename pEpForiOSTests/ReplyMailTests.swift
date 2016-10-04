//
//  ReplyMailTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class ReplyMailTests: XCTestCase {

    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()
    }

    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }

    func testCitationTitle() {
        let from = persistentSetup.model.insertOrUpdateContactEmail("a@b", name: "Abe")
        let to = persistentSetup.model.insertOrUpdateContactEmail("a@b", name: "Abe")
        let cc = persistentSetup.model.insertOrUpdateContactEmail("b@a", name: "Beata")
        let message = persistentSetup.model.insertNewMessage()
        message.receivedDate = Date.init()
        message.from = from as? Contact

        message.to = NSOrderedSet.init(object: to)
        message.cc = NSOrderedSet.init(object: cc)

        XCTAssertTrue(ReplyUtil.citationHeaderForMessage(
            message, replyAll: false).startsWith("Abe wrote on"))

        XCTAssertTrue(ReplyUtil.citationHeaderForMessage(
            message, replyAll: true).startsWith("Abe, Beata wrote on"))
    }
}
