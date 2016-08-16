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
            "INBOX", accountEmail: accountEmail))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Drafts", accountEmail: accountEmail))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Sent Mails", accountEmail: accountEmail))
    }

    func testSimpleContactSearch() {
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("xtes").count, 5)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("XtEs").count, 5)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("wha").count, 1)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("Ano").count, 1)
        XCTAssertEqual(persistentSetup.model.contactsBySnippet("ANO").count, 1)
    }

    func testSpecialFolders() {
        XCTAssertNotNil(persistentSetup.model.folderInboxForEmail(accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderSentMailsForEmail(accountEmail))
        XCTAssertNotNil(persistentSetup.model.folderDraftsForEmail(accountEmail))
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

    func testInsertOrUpdatePantomimeMailEncrypted() {
        guard let data = TestUtil.loadDataWithFileName(
            "EncryptedHTMLMail_to_1776_713B_CBD8_8630_4FE2__7F13_60DA_23E2_1288_21FE.txt") else {
            XCTAssertTrue(false)
            return
        }
        let message = CWIMAPMessage.init(data: data)
        message.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))
        let model = persistentSetup.model
        guard let theMsg = model.insertOrUpdatePantomimeMail(
            message, accountEmail: persistentSetup.accountEmail,
            forceParseAttachments: true) else {
                XCTAssertTrue(false)
                return
        }
        XCTAssertNil(theMsg.longMessage)
        XCTAssertNil(theMsg.longMessageFormatted)
        XCTAssertEqual(theMsg.attachments.count, 2)

        let encAttachment = theMsg.attachments[1] as? IAttachment
        XCTAssertNotNil(encAttachment)
        if let attach = encAttachment {
            let encData = attach.data
            XCTAssertNotNil(encData)
            if let data = encData {
                if let s = String.init(data: data, encoding: NSASCIIStringEncoding) {
                    XCTAssertTrue(s.contains("-----BEGIN PGP MESSAGE-----"))
                } else {
                    XCTAssertTrue(false)
                }
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }

        let session = PEPSession.init()

        // Import public key for myself
        TestUtil.importKeyByFileName(
            session, fileName: "1776_713B_CBD8_8630_4FE2__7F13_60DA_23E2_1288_21FE.asc")

        let identity = NSMutableDictionary()
        identity[kPepUsername] = "myself"
        identity[kPepAddress] = "unittest.ios.4@peptest.ch"
        identity[kPepFingerprint] = "1776713BCBD886304FE27F1360DA23E2128821FE"
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])
        XCTAssertEqual(
            identity[kPepFingerprint] as? String,
            "1776713BCBD886304FE27F1360DA23E2128821FE")

        let dict = PEPUtil.pepMail(theMsg)
        var pepDecryptedMail: NSDictionary?
        var keys: NSArray?
        let color = session.decryptMessageDict(
            dict, dest: &pepDecryptedMail, keys: &keys)
        XCTAssertGreaterThanOrEqual(color.rawValue, PEP_rating_reliable.rawValue)
    }
}