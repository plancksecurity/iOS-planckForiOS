//
//  ModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

/**
 Equality (==) for 3-tuples of optional Strings.
 */
func ==<T1: Equatable, T2: Equatable, T3: Equatable>(
    lhs: (T1?, T2?, T3?), rhs: (T1?, T2?, T3?)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1 && lhs.2 == rhs.2
}

class ModelTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    let waitTime: NSTimeInterval = 10

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()

        // Some contacts
        for i in 1...5 {
            let contact = persistentSetup.model.insertOrUpdateContactEmail(
                "email\(i)@xtest.de", name: "name\(i)")
            XCTAssertNotNil(contact)
        }
        let contact = persistentSetup.model.insertOrUpdateContactEmail(
            "wha@wawa.com", name: "Another")
        XCTAssertNotNil(contact)

        let connectInfo = ConnectInfo.init(
            nameOfTheUser: "The User",
            email: "test001@peptest.ch", imapServerName: "imapServer",
            smtpServerName: "smtpServer")
        XCTAssertNotNil(persistentSetup.model.insertAccountFromConnectInfo(connectInfo))

        // Some folders
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX", accountEmail: "test001@peptest.ch"))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Drafts", accountEmail: "test001@peptest.ch"))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Sent Mails", accountEmail: "test001@peptest.ch"))
    }

    func testSimpleContactSearch() {
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("xtes").count, 5)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("XtEs").count, 5)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("wha").count, 1)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("Ano").count, 1)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("ANO").count, 1)
    }

    func testSpecialFolders() {
        XCTAssertNotNil(persistentSetup.model.folderInboxForEmail(
            persistentSetup.connectionInfo.email))
        XCTAssertNotNil(persistentSetup.model.folderSentMailsForEmail(
            persistentSetup.connectionInfo.email))
        XCTAssertNotNil(persistentSetup.model.folderDraftsForEmail(
            persistentSetup.connectionInfo.email))
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
        let ab = AddressBook()

        let insertTestContacts = {
            XCTAssertTrue(ab.addContact(
                AddressbookContact.init(email: "none@test.com", name: "Noone Particular")))
            XCTAssertTrue(ab.addContact(
                AddressbookContact.init(email: "hahaha1@test.com", name: "Hahaha1")))
            XCTAssertTrue(ab.addContact(
                AddressbookContact.init(email: "hahaha2@test.com", name: "Hahaha2")))
            XCTAssertTrue(ab.addContact(
                AddressbookContact.init(email: "uhum3@test.com", name: "This Is Not")))
            XCTAssertTrue(ab.save())
        }

        let testBlock = {
            insertTestContacts()
            XCTAssertEqual(ab.contactsBySnippet("NONEAtyvAll").count, 0)
            XCTAssertEqual(ab.contactsBySnippet("NONE").count, 1)
            XCTAssertEqual(ab.contactsBySnippet("none").count, 1)
            XCTAssertEqual(ab.contactsBySnippet("hah").count, 2)
            XCTAssertEqual(ab.contactsBySnippet("hAHa2").count, 1)
            XCTAssertEqual(ab.contactsBySnippet("This is").count, 1)
            XCTAssertEqual(ab.contactsBySnippet("This").count, 1)
            XCTAssertEqual(ab.contactsBySnippet("test").count, 4)
        }

        // We need authorization for this test to work
        if ab.authorizationStatus == .NotDetermined {
            let exp = expectationWithDescription("granted")
            ab.authorize({ ab in
                exp.fulfill()
            })
            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                XCTAssertTrue(ab.authorizationStatus == .Authorized)
                testBlock()
            })
        } else {
            XCTAssertTrue(ab.authorizationStatus == .Authorized)
            testBlock()
        }
    }
}
