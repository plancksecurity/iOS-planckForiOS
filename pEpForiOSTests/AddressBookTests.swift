//
//  AddressBookTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import Contacts

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
        XCTAssertTrue(ab.splitContactNameInTuple("uiae   dtrn   123  qfgh") == (
            "uiae", "dtrn 123", "qfgh"))
        XCTAssertTrue(ab.splitContactNameInTuple("") == (nil, nil, nil))
        XCTAssertTrue(ab.splitContactNameInTuple("uiae") == ("uiae", nil, nil))
        XCTAssertTrue(ab.splitContactNameInTuple("uiae   xvlc") == ("uiae", nil, "xvlc"))
    }

    func insertContactWithPicture(givenName: String, lastName: String, email: String) {
        guard let imageData = TestUtil.loadDataWithFileName(
            "PorpoiseGalaxy_HubbleFraile_960.jpg") else {
                XCTAssertTrue(false)
                return
        }

        let contact = CNMutableContact()

        contact.imageData = imageData

        contact.givenName = givenName
        contact.familyName = lastName

        let homeEmail = CNLabeledValue(label:CNLabelHome, value:email as NSString)
        contact.emailAddresses = [homeEmail]

        // Saving the newly created contact
        let store = CNContactStore()
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier:nil)
        do {
            try store.execute(saveRequest)
        } catch {
            XCTFail()
        }
    }

    func testAddressBookTransfer() {
        let ab = AddressBook()
        guard ab.isAuthorized() else {
            XCTFail()
            return
        }

        insertContactWithPicture(givenName: "John", lastName: "Appleseed",
                                 email: "john@example.com")

        let expAddressbookSynced = expectation(description: "expAddressbookSynced")

        DispatchQueue.global(qos: .userInitiated).async {
            AddressBook.checkAndTransfer()
            expAddressbookSynced.fulfill()
        }
        waitForExpectations(timeout: waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let cdIdentities = CdIdentity.all() as? [CdIdentity] ?? []
        XCTAssertGreaterThan(cdIdentities.count, 0)

        for cdId in cdIdentities {
            XCTAssertNotNil(cdId.address)
            XCTAssertNotNil(cdId.userName)
            XCTAssertNotNil(cdId.userID)
        }
    }
}
