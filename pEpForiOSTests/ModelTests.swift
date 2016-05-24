//
//  ModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class ModelTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()

        // Some contacts
        for i in 1..<5 {
            let contact = persistentSetup.model.insertOrUpdateContactEmail(
                "email\(i)@test.de", name: "name\(i)")
            XCTAssertNotNil(contact)
        }
        let contact = persistentSetup.model.insertOrUpdateContactEmail(
            "wha@wawa.com", name: "Another")
        XCTAssertNotNil(contact)

        let connectInfo = ConnectInfo.init(
            email: "test001@peptest.ch", imapServerName: "imapServer",
            smtpServerName: "smtpServer")
        XCTAssertNotNil(persistentSetup.model.insertAccountFromConnectInfo(connectInfo))

        // Some folders
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX", folderType: Account.AccountType.IMAP, accountEmail: "test001@peptest.ch"))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Drafts", folderType: Account.AccountType.IMAP,
            accountEmail: "test001@peptest.ch"))
        XCTAssertNotNil(persistentSetup.model.insertOrUpdateFolderName(
            "INBOX.Sent Mails", folderType: Account.AccountType.IMAP,
            accountEmail: "test001@peptest.ch"))
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

    func testSpecialFolders() {
        XCTAssertNotNil(persistentSetup.model.folderInbox())
        XCTAssertNotNil(persistentSetup.model.folderSentMails())
        XCTAssertNotNil(persistentSetup.model.folderDrafts())
    }
}
