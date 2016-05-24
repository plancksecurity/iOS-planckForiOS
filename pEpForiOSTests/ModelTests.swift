//
//  ModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class ModelTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()

        for i in 1..<5 {
            let contact = persistentSetup.model.insertOrUpdateContactEmail(
                "email\(i)@test.de", name: "name\(i)")
            XCTAssertNotNil(contact)
        }
        let contact = persistentSetup.model.insertOrUpdateContactEmail(
            "wha@wawa.com", name: "Another")
        XCTAssertNotNil(contact)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSimpleContactSearch() {
        var contacts = persistentSetup.model.getContactsBySnippet("test")
        XCTAssertEqual(contacts.count, 10)
        contacts = persistentSetup.model.getContactsBySnippet("wha")
        XCTAssertEqual(contacts.count, 1)
        contacts = persistentSetup.model.getContactsBySnippet("Ano")
        XCTAssertEqual(contacts.count, 1)
    }
}
