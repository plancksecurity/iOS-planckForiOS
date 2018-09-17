//
//  MailParsingTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 17.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class MailParsingTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    var cdOwnAccount: CdAccount!
    var fromIdent: PEPIdentity!

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())
        persistentSetup = PersistentSetup()

        let cdMyAccount = SecretTestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdMyAccount
        Record.saveAndWait()

        cdOwnAccount = cdMyAccount
    }

    override func tearDown() {
        PEPSession.cleanup()
        super.tearDown()
    }

    func testMailParsing() {
        let pEpMySelfIdentity = cdOwnAccount.pEpIdentity()

        let session = PEPSession()
        try! session.mySelf(pEpMySelfIdentity)
        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "HandshakeTests_mail_001.txt",
            cdOwnAccount: cdOwnAccount) else {
                XCTFail()
                return
        }

        let pEpMessage = cdMessage.pEpMessage()

        let theAttachments = pEpMessage.attachments ?? []
        XCTAssertEqual(theAttachments.count, 2)
        XCTAssertEqual(theAttachments[0].mimeType, "plain/text")
        XCTAssertEqual(theAttachments[1].mimeType, "application/pgp-keys")

        guard let optFields = pEpMessage.optionalFields else {
            XCTFail("expected optional_fields to be defined")
            return
        }
        var foundXpEpVersion = false
        for innerArray in optFields {
            if innerArray.count == 2 {
                if innerArray[0] == "X-pEp-Version" {
                    foundXpEpVersion = true
                }
            } else {
                XCTFail("corrupt optional fields element")
            }
        }
        XCTAssertTrue(foundXpEpVersion)
    }
}
