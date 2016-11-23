//
//  ModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

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
        persistentSetup = PersistentSetup()

        // Some contacts
        for i in 1...5 {
            let contact = Identity.create(
                address: "email\(i)@xtest.de", userName: "name\(i)")
            XCTAssertNotNil(contact)
        }
        let contact = Identity.create(
            address: "wha@wawa.com", userName: "Another")
        XCTAssertNotNil(contact)

        // Some folders
        for name in [ImapSync.defaultImapInboxName, "\(ImapSync.defaultImapInboxName).Drafts",
                     "\(ImapSync.defaultImapInboxName).Sent Mails"] {
                        let _ = Folder.create(name: name)
        }
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testFolderLookUp() {
        XCTAssertFalse(Folder.by(folderType: FolderType.inbox).isEmpty)
        XCTAssertFalse(Folder.by(folderType: FolderType.sent).isEmpty)
        XCTAssertFalse(Folder.by(folderType: FolderType.drafts).isEmpty)
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
