//
//  AddressBookTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class AddressBookTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    let waitTime = TestUtil.modelSaveWaitTime

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testSimpleContactSearch() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        // Some contacts
        for i in 1...5 {
            let _ = Identity.create(
                address: "email\(i)@xtest.de", userName: "name\(i)")
        }
        let _ = Identity.create(
            address: "wha@wawa.com", userName: "Another")

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThan(Identity.all().count, 0)

        XCTAssertEqual(Identity.by(snippet: "xtes").count, 5)
        XCTAssertEqual(Identity.by(snippet: "XtEs").count, 5)
        XCTAssertEqual(Identity.by(snippet: "wha").count, 1)
        XCTAssertEqual(Identity.by(snippet: "Ano").count, 1)
        XCTAssertEqual(Identity.by(snippet: "ANO").count, 1)
    }

    func testSplitContactName() {
        let ab = AddressBook()
        XCTAssertTrue(ab.splitContactNameInTuple("uiae dtrn qfgh") == ("uiae", "dtrn", "qfgh"))
        XCTAssertTrue(ab.splitContactNameInTuple("uiae   dtrn    qfgh") == ("uiae", "dtrn", "qfgh"))
        XCTAssertTrue(ab.splitContactNameInTuple("uiae   dtrn   123  qfgh") == ("uiae", "dtrn 123",
                                                                                "qfgh"))
        XCTAssertTrue(ab.splitContactNameInTuple("") == (nil, nil, nil))
        XCTAssertTrue(ab.splitContactNameInTuple("uiae") == ("uiae", nil, nil))
        XCTAssertTrue(ab.splitContactNameInTuple("uiae   xvlc") == ("uiae", nil, "xvlc"))
    }

    func testAddressbook() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        let _ = Identity.create(address: "none@test.com", userName: "Noone Particular")
        let _ = Identity.create(address: "hahaha1@test.com", userName: "Hahaha1")
        let _ = Identity.create(address: "hahaha2@test.com", userName: "Hahaha2")
        let _ = Identity.create(address: "uhum3@test.com", userName: "This Is Not")

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThan(Identity.all().count, 0)
        XCTAssertEqual(Identity.by(snippet: "NONEAtyvAll").count, 0)
        XCTAssertEqual(Identity.by(snippet: "NONE").count, 1)
        XCTAssertEqual(Identity.by(snippet: "none").count, 1)
        XCTAssertEqual(Identity.by(snippet: "hah").count, 2)
        XCTAssertEqual(Identity.by(snippet: "hAHa2").count, 1)
        XCTAssertEqual(Identity.by(snippet: "This is").count, 1)
        XCTAssertEqual(Identity.by(snippet: "This").count, 1)
        XCTAssertEqual(Identity.by(snippet: "test").count, 4)
    }

    func testAddressBookTransfer() {
        MessageModelConfig.observer.delegate = ObserverDelegate(
            expSaved: expectation(description: "saved"))

        AddressBook.checkAndTransfer()

        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThan((CdIdentity.all() ?? []).count, 0)
    }
}
