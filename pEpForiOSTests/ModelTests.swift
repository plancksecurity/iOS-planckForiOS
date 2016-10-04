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
            FolderType.inbox, email: persistentSetup.accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.sent, email: persistentSetup.accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderByType(
            FolderType.drafts, email: persistentSetup.accountEmail))
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
            let expAddressBookTransfered = self.expectation(
                description: "expAddressBookTransfered")
            let persistentSetup = PersistentSetup.init()
            let context = persistentSetup.coreDataUtil.privateContext()
            var contactsCount = 0
            MiscUtil.transferAddressBook(context, blockFinished: { contacts in
                XCTAssertGreaterThan(contacts.count, 0)
                contactsCount = contacts.count
                expAddressBookTransfered.fulfill()
            })
            self.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
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

        for f: PantomimeFlag in [.answered, .deleted, .draft, .recent, .seen] {
            XCTAssertFalse(m.pantomimeFlags().contain(f))
        }
        XCTAssertTrue(m.pantomimeFlags().contain(.flagged))

        m.flagAnswered = true
        XCTAssertFalse(m.pantomimeFlags().contain(.answered))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.answered))

        m.flagDeleted = true
        XCTAssertFalse(m.pantomimeFlags().contain(.deleted))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.deleted))

        m.flagRecent = true
        XCTAssertFalse(m.pantomimeFlags().contain(.recent))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.recent))

        m.flagDraft = true
        XCTAssertFalse(m.pantomimeFlags().contain(.draft))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.draft))

        m.flagSeen = true
        XCTAssertFalse(m.pantomimeFlags().contain(.seen))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.seen))
    }

    func testCWFlagsAsShort() {
        let fl = CWFlags.init()
        fl.add(.recent)
        XCTAssertEqual(fl.rawFlagsAsShort(), 8)

        fl.add(.answered)
        XCTAssertEqual(fl.rawFlagsAsShort(), 9)

        fl.add(.deleted)
        XCTAssertEqual(fl.rawFlagsAsShort(), 41)

        fl.add(.seen)
        XCTAssertEqual(fl.rawFlagsAsShort(), 57)
    }

    func testUpdateFlags() {
        let m = persistentSetup.model.insertNewMessage()
        XCTAssertEqual(m.flags.int16Value, 0)

        var valuesSoFar: Int16 = 0
        for fl in [PantomimeFlag.answered, .draft, .flagged, .recent, .seen, .deleted] {
            switch fl {
            case .answered:
                m.flagAnswered = true
            case .draft:
                m.flagDraft = true
            case .flagged:
                m.flagFlagged = true
            case .recent:
                m.flagRecent = true
            case .seen:
                m.flagSeen = true
            case .deleted:
                m.flagDeleted = true
            }
            valuesSoFar += Int(fl.rawValue)
            m.updateFlags()
            XCTAssertEqual(m.flags.int16Value, valuesSoFar)
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
        m.flagsFromServer = NSNumber.init(value: CWFlags.init(
            flags: PantomimeFlag.deleted).rawFlagsAsShort() as Int16)
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
