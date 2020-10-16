//
//  MessagePantomimeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PantomimeFramework
import PEPObjCAdapterFramework

class MessagePantomimeTests: PersistentStoreDrivenTestBase {

    func testPantomimeFlagsFromMessage() {
        let m = CdMessage(context: moc)
        m.imap = CdImapFields(context: moc)

        let cdFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = cdFlags

        cdFlags.flagFlagged = true

        for f: PantomimeFlag in [.answered, .deleted, .draft, .recent, .seen] {
            XCTAssertFalse(m.pantomimeFlags().contain(f))
        }
        XCTAssertTrue(m.pantomimeFlags().contain(.flagged))

        cdFlags.flagAnswered = true
        XCTAssertTrue(m.pantomimeFlags().contain(.answered))

        cdFlags.flagDeleted = true
        XCTAssertTrue(m.pantomimeFlags().contain(.deleted))

        cdFlags.flagRecent = true
        XCTAssertTrue(m.pantomimeFlags().contain(.recent))

        cdFlags.flagDraft = true
        XCTAssertTrue(m.pantomimeFlags().contain(.draft))

        cdFlags.flagSeen = true
        XCTAssertTrue(m.pantomimeFlags().contain(.seen))
    }

    func testCWFlagsAsShort() {
        let fl = CWFlags()
        fl.add(.recent)
        XCTAssertEqual(fl.rawFlagsAsShort(), 8)

        fl.add(.answered)
        XCTAssertEqual(fl.rawFlagsAsShort(), 9)

        fl.add(.deleted)
        XCTAssertEqual(fl.rawFlagsAsShort(), 41)

        fl.add(.seen)
        XCTAssertEqual(fl.rawFlagsAsShort(), 57)
    }

    func testReferences() {
        let testData = SecretTestData()
        let refs = ["ref1", "ref2", "ref3"]
        let inReplyTo = "ref4"
        var allRefs = refs
        allRefs.append(inReplyTo)

        let cdAccount = testData.createWorkingCdAccount(context: moc)

        let cdFolder = CdFolder(context: moc)
        let folderName = "inbox"
        cdFolder.folderType = FolderType.inbox
        cdFolder.name = folderName
        cdFolder.account = cdAccount

        let cwFolder = CWFolder(name: folderName)

        let cwMsg = CWIMAPMessage()
        cwMsg.setReferences(refs)
        cwMsg.setFolder(cwFolder)
        cwMsg.setInReplyTo(inReplyTo)

        let update = CWMessageUpdate()
        update.rfc822 = true
        guard let cdMsg = CdMessage.insertOrUpdate(
            pantomimeMessage: cwMsg, account: cdAccount, messageUpdate: update, context: moc) else {
                XCTFail()
                return
        }
        let cdRefs = cdMsg.references?.array as? [CdMessageReference] ?? []
        XCTAssertEqual(cdRefs.count, refs.count) // inReplyTo not taken into account anymore

        let pEpMsg = cdMsg.pEpMessage()
        XCTAssertEqual(pEpMsg.references ?? [], refs) // inReplyTo not taken into account anymore

        let cwMsg2 = PEPUtils.pantomime(pEpMessage: pEpMsg)
        XCTAssertEqual(cwMsg2.allReferences() as? [String] ?? [], allRefs)
    }
}
