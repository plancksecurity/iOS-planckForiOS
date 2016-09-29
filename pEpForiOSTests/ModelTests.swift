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
            email: persistentSetup.accountEmail, imapServerName: "imapServer",
            smtpServerName: "smtpServer")
        XCTAssertNotNil(persistentSetup.model.insertAccountFromConnectInfo(connectInfo))

        // Some folders
        for name in [ImapSync.defaultImapInboxName, "\(ImapSync.defaultImapInboxName).Drafts",
                     "\(ImapSync.defaultImapInboxName).Sent Mails"] {
                        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
                            name, folderSeparator: ".", accountEmail: persistentSetup.accountEmail))
                        XCTAssertNotNil(persistentSetup.model.folderByName(name,
                            email: persistentSetup.accountEmail))
                        print("Created \(name) (\(persistentSetup.accountEmail))")
        }
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
            FolderType.Inbox, email: persistentSetup.accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.Sent, email: persistentSetup.accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.Drafts, email: persistentSetup.accountEmail))
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
                                    waitTime: TestUtil.waitTime)
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
            self.waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })
            let model = persistentSetup.model
            let contacts = model.contactsByPredicate(NSPredicate.init(value: true),
                                                     sortDescriptors: [])
            XCTAssertEqual(contacts?.count, contactsCount)
        }

        TestUtil.runAddressBookTest(testBlock, addressBook: ab, testCase: self,
                                    waitTime: TestUtil.waitTime)
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
        m.updateFlags()

        for f: PantomimeFlag in [.Answered, .Deleted, .Draft, .Recent, .Seen] {
            XCTAssertFalse(m.pantomimeFlags().contain(f))
        }
        XCTAssertTrue(m.pantomimeFlags().contain(.Flagged))

        m.flagAnswered = true
        XCTAssertFalse(m.pantomimeFlags().contain(.Answered))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.Answered))

        m.flagDeleted = true
        XCTAssertFalse(m.pantomimeFlags().contain(.Deleted))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.Deleted))

        m.flagRecent = true
        XCTAssertFalse(m.pantomimeFlags().contain(.Recent))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.Recent))

        m.flagDraft = true
        XCTAssertFalse(m.pantomimeFlags().contain(.Draft))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.Draft))

        m.flagSeen = true
        XCTAssertFalse(m.pantomimeFlags().contain(.Seen))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.Seen))
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

    func testUpdateFlags() {
        let m = persistentSetup.model.insertNewMessage()
        XCTAssertEqual(m.flags.shortValue, 0)

        var valuesSoFar: Int16 = 0
        for fl in [PantomimeFlag.Answered, .Draft, .Flagged, .Recent, .Seen, .Deleted] {
            switch fl {
            case .Answered:
                m.flagAnswered = true
            case .Draft:
                m.flagDraft = true
            case .Flagged:
                m.flagFlagged = true
            case .Recent:
                m.flagRecent = true
            case .Seen:
                m.flagSeen = true
            case .Deleted:
                m.flagDeleted = true
            }
            valuesSoFar += Int(fl.rawValue)
            m.updateFlags()
            XCTAssertEqual(m.flags.shortValue, valuesSoFar)
        }
    }

    func testStoreCommandForUpdate() {
        let m = persistentSetup.model.insertNewMessage()
        m.uid = 1024
        m.flagsFromServer = 0
        m.flagDeleted = true
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate().0,
                       "UID STORE 1024 FLAGS.SILENT (\\Deleted)")

        // Check if 'difference' is taken into account
        m.flagsFromServer = NSNumber.init(short: CWFlags.init(
            flags: PantomimeFlag.Deleted).rawFlagsAsShort())
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate().0,
                       "UID STORE 1024 FLAGS.SILENT (\\Deleted)")

        m.flagAnswered = true
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate().0,
                       "UID STORE 1024 FLAGS.SILENT (\\Answered \\Deleted)")

        m.flagSeen = true
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate().0,
                       "UID STORE 1024 FLAGS.SILENT (\\Answered \\Seen \\Deleted)")

        m.flagFlagged = true
        m.updateFlags()
        XCTAssertEqual(
            m.storeCommandForUpdate().0,
            "UID STORE 1024 FLAGS.SILENT (\\Answered \\Flagged \\Seen \\Deleted)")
    }
}