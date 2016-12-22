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
