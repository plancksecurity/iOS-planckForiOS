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
    let accountEmail = "unittest.ios.4@peptest.ch"

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
            email: accountEmail, imapServerName: "imapServer",
            smtpServerName: "smtpServer")
        XCTAssertNotNil(persistentSetup.model.insertAccountFromConnectInfo(connectInfo))

        // Some folders
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX", folderSeparator: ".", accountEmail: accountEmail))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Drafts", folderSeparator: ".", accountEmail: accountEmail))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Sent Mails", folderSeparator: ".", accountEmail: accountEmail))
    }

    func testSimpleContactSearch() {
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("xtes").count, 5)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("XtEs").count, 5)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("wha").count, 1)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("Ano").count, 1)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("ANO").count, 1)
    }

    func testFolderLookUp() {
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.Inbox, email: accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.Sent, email: accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.Drafts, email: accountEmail))
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
        TestUtil.runAddressBookTest(testBlock, addressBook: ab, testCase: self,
                                    waitTime: waitTime)
    }

    func testAddressBookTransfer() {
        let ab = AddressBook()

        let testBlock = {
            let expAddressBookTransfered = self.expectationWithDescription(
                "expAddressBookTransfered")
            let persistentSetup = PersistentSetup.init()
            let context = persistentSetup.coreDataUtil.privateContext()
            var contactsCount = 0
            MiscUtil.transferAddressBook(context, blockFinished: { contacts in
                XCTAssertGreaterThan(contacts.count, 0)
                contactsCount = contacts.count
                expAddressBookTransfered.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.waitTime, handler: { error in
                XCTAssertNil(error)
            })
            let model = persistentSetup.model
            let contacts = model.contactsByPredicate(NSPredicate.init(value: true),
                                                     sortDescriptors: [])
            XCTAssertEqual(contacts?.count, contactsCount)
        }

        TestUtil.runAddressBookTest(testBlock, addressBook: ab, testCase: self,
                                    waitTime: waitTime)
    }

    func testInsertOrUpdatePantomimeMail() {
        guard let data = TestUtil.loadDataWithFileName("UnencryptedHTMLMail.txt") else {
            XCTAssertTrue(false)
            return
        }
        let message = CWIMAPMessage.init(data: data)
        message.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))
        let model = persistentSetup.model
        let msg = model.insertOrUpdatePantomimeMail(
            message, accountEmail: persistentSetup.accountEmail,
            forceParseAttachments: true)
        XCTAssertNotNil(msg)
        if let m = msg {
            XCTAssertNotNil(m.longMessage)
            XCTAssertNotNil(m.longMessageFormatted)
        }
    }

    func testPantomimeFlagsFromMessage() {
        let m = persistentSetup.model.insertNewMessage()
        m.flagFlagged = true

        for f: PantomimeFlag in [.Answered, .Deleted, .Draft, .Recent, .Seen] {
            XCTAssertFalse(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(f))
        }
        XCTAssertTrue(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(.Flagged))

        m.flagAnswered = true
        XCTAssertTrue(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(.Answered))

        m.flagDeleted = true
        XCTAssertTrue(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(.Deleted))

        m.flagRecent = true
        XCTAssertTrue(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(.Recent))

        m.flagDraft = true
        XCTAssertTrue(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(.Draft))

        m.flagSeen = true
        XCTAssertTrue(persistentSetup.model.pantomimeFlagsFromMessage(m).contain(.Seen))
    }

    func testCWFlagsAsShort() {
        let fl = CWFlags.init()
        fl.add(.Recent)
        XCTAssertEqual(fl.rawFlagsAsShort(), 8)

        fl.add(.Answered)
        XCTAssertEqual(fl.rawFlagsAsShort(), 9)

        fl.add(.Deleted)
        XCTAssertEqual(fl.rawFlagsAsShort(), 41)

        fl.add(.Seen)
        XCTAssertEqual(fl.rawFlagsAsShort(), 57)
    }

    func testAutomaticFlagsUpdate() {
        let m = persistentSetup.model.insertNewMessage()
        XCTAssertEqual(m.flags.shortValue, 0)

        for fl in [] {

        }
        m.flagDeleted = true
        XCTAssertEqual(m.flags.shortValue, 32)
    }
}