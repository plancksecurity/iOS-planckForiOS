//
//  MiscTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

import pEpForiOS

/**
 Tests for things not covered elsewhere.
 */
class MiscTests: XCTestCase {
    let waitTime: NSTimeInterval = 10

    func testSignedNumbers32() {
        let u: UInt32 = UInt32.max
        let s: Int32 = Int32(bitPattern: u)
        let u1: UInt32 = UInt32(bitPattern: s)
        XCTAssertEqual(u1, UInt32.max)

        let n = NSNumber.init(int: s)
        let u2: UInt32 = UInt32(bitPattern: n.intValue)
        XCTAssertEqual(u2, UInt32.max)
    }

    func testAddressBookTransfer() {
        let expAddressBookTransfered = expectationWithDescription("expAddressBookTransfered")
        let persistentSetup = PersistentSetup.init()
        let context = persistentSetup.coreDataUtil.privateContext()
        var contactsCount = 0
        MiscUtil.transferAddressBook(context, blockFinished: { contacts in
            XCTAssertGreaterThan(contacts.count, 0)
            contactsCount = contacts.count
            expAddressBookTransfered.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        let model = persistentSetup.model
        let contacts = model.contactsByPredicate(NSPredicate.init(value: true),
                                                 sortDescriptors: [])
        XCTAssertEqual(contacts?.count, contactsCount)
    }
}