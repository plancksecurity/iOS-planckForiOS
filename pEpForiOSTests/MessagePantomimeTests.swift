//
//  MessagePantomimeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class MessagePantomimeTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testPantomimeFlagsFromMessage() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.imap?.flagFlagged = true
        m.imap?.updateCurrentFlags()

        for f: PantomimeFlag in [.answered, .deleted, .draft, .recent, .seen] {
            XCTAssertFalse(m.pantomimeFlags().contain(f))
        }
        XCTAssertTrue(m.pantomimeFlags().contain(.flagged))

        m.imap?.flagAnswered = true
        XCTAssertTrue(m.pantomimeFlags().contain(.answered))

        m.imap?.flagDeleted = true
        XCTAssertTrue(m.pantomimeFlags().contain(.deleted))

        m.imap?.flagRecent = true
        XCTAssertTrue(m.pantomimeFlags().contain(.recent))

        m.imap?.flagDraft = true
        XCTAssertTrue(m.pantomimeFlags().contain(.draft))

        m.imap?.flagSeen = true
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
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        XCTAssertEqual(m.imap?.flagsFromServer, 0)

        var valuesSoFar: Int16 = 0
        for fl in [PantomimeFlag.answered, .draft, .flagged, .recent, .seen, .deleted] {
            switch fl {
            case .answered:
                m.imap?.flagAnswered = true
            case .draft:
                m.imap?.flagDraft = true
            case .flagged:
                m.imap?.flagFlagged = true
            case .recent:
                m.imap?.flagRecent = true
            case .seen:
                m.imap?.flagSeen = true
            case .deleted:
                m.imap?.flagDeleted = true
            }
            m.imap?.updateCurrentFlags()
            valuesSoFar += Int(fl.rawValue)
            XCTAssertEqual(m.imap?.flagsCurrent, valuesSoFar)
        }
    }

    func testStoreCommandForUpdate() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = 0
        m.imap?.flagDeleted = true
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Deleted)")

        // Check if 'difference' is taken into account
        m.imap?.flagsFromServer = CWFlags(flags: PantomimeFlag.deleted).rawFlagsAsShort()
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Deleted)")

        m.imap?.flagAnswered = true
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Answered \\Deleted)")

        m.imap?.flagSeen = true
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Answered \\Seen \\Deleted)")

        m.imap?.flagFlagged = true
        XCTAssertEqual(
            m.storeCommandForUpdate()?.0,
            "UID STORE 1024 FLAGS.SILENT (\\Answered \\Flagged \\Seen \\Deleted)")
    }

    func testReferences() {
        let testData = TestData()
        let refs = ["ref1", "ref2", "ref3"]
        let inReplyTo = "ref4"
        var allRefs = refs
        allRefs.append(inReplyTo)

        let cdAccount = testData.createWorkingCdAccount()

        let cdFolder = CdFolder.create()
        let folderName = "inbox"
        cdFolder.folderType = FolderType.inbox.rawValue
        cdFolder.name = folderName
        cdFolder.uuid = MessageID.generate()
        cdFolder.account = cdAccount

        let cwFolder = CWFolder(name: folderName)

        let cwMsg = CWIMAPMessage()
        cwMsg.setReferences(refs)
        cwMsg.setFolder(cwFolder)
        cwMsg.setInReplyTo(inReplyTo)

        let update = CWMessageUpdate()
        update.rfc822 = true
        guard let cdMsg = CdMessage.insertOrUpdate(
            pantomimeMessage: cwMsg, account: cdAccount, messageUpdate: update) else {
                XCTFail()
                return
        }
        let cdRefs = cdMsg.references?.array as? [CdMessageReference] ?? []
        XCTAssertEqual(cdRefs.count, refs.count + 1)

        guard let msg = cdMsg.message() else {
            XCTFail()
            return
        }
        XCTAssertEqual(msg.references.count, refs.count + 1)
        XCTAssertEqual(msg.references, allRefs)

        let pEpMsg = cdMsg.pEpMessage()
        XCTAssertEqual(pEpMsg[kPepReferences] as? [String] ?? [], allRefs)

        let cwMsg2 = PEPUtil.pantomime(pEpMessage: pEpMsg)
        XCTAssertEqual(cwMsg2.allReferences() as? [String] ?? [], allRefs)
    }
}
