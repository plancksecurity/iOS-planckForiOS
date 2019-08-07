//
//  MailParsingTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 17.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel
import PEPObjCAdapterFramework

class MailParsingTests: CoreDataDrivenTestBase {
    var fromIdent: PEPIdentity!

    override func setUp() {
        super.setUp()

        let cdMyAccount = SecretTestData().createWorkingCdAccount(number: 0, context: moc)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder(context: moc)
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.account = cdMyAccount
        moc.saveAndLogErrors()

        cdAccount = cdMyAccount
    }

    func testParseUnencryptedMailWithPublicKey() {
        let pEpMySelfIdentity = cdAccount.pEpIdentity()

        let session = PEPSession()
        try! session.mySelf(pEpMySelfIdentity)
        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)

        guard let cdMessage = TestUtil.cdMessage(fileName: "HandshakeTests_mail_001.txt",
                                                 cdOwnAccount: cdAccount)
            else {
                XCTFail()
                return
        }

        let pEpMessage = PEPUtils.pEp(cdMessage: cdMessage, outgoing: true)

        let theAttachments = pEpMessage.attachments ?? []
        XCTAssertEqual(theAttachments.count, 1)
        XCTAssertEqual(theAttachments[0].mimeType, ContentTypeUtils.ContentType.pgpKeys)

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

    func testParseUndisplayableHTMLMessage() {
        let pEpMySelfIdentity = cdAccount.pEpIdentity()

        let session = PEPSession()
        try! session.mySelf(pEpMySelfIdentity)
        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)

        guard let cdMessage = TestUtil.cdMessage(fileName: "Undisplayable_HTML_Message.txt",
                                                 cdOwnAccount: cdAccount)
            else {
                XCTFail()
                return
        }

        let pEpMessage = PEPUtils.pEp(cdMessage: cdMessage, outgoing: true)

        let theAttachments = pEpMessage.attachments ?? []
        XCTAssertEqual(theAttachments.count, 2)
        XCTAssertEqual(theAttachments[0].mimeType, "image/jpeg")
        XCTAssertEqual(theAttachments[1].mimeType, "image/png")

        XCTAssertEqual(pEpMessage.shortMessage, "Sendung von BlahTex BlahBlah AG - zugestellt")
        XCTAssertNil(pEpMessage.longMessage)

        guard let htmlMessage = pEpMessage.longMessageFormatted else {
            XCTFail()
            return
        }

        XCTAssertTrue(htmlMessage.contains("Guten Tag Herr Müller"))
        XCTAssertTrue(htmlMessage.contains(find: "Sendungsnummer"))
        XCTAssertTrue(htmlMessage.contains(find: "585862075329118547"))
    }

    /**
     IOS-1364
     */
    func testParseUndisplayedAttachedJpegMessage() {
        let pEpMySelfIdentity = cdAccount.pEpIdentity()

        let session = PEPSession()
        try! session.mySelf(pEpMySelfIdentity)
        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)

        guard let cdMessage = TestUtil.cdMessage(fileName: "1364_Mail_missing_attached_image.txt",
                                                 cdOwnAccount: cdAccount)
            else {
                XCTFail()
                return
        }

        let pEpMessage = PEPUtils.pEp(cdMessage: cdMessage, outgoing: true)

        XCTAssertEqual(pEpMessage.shortMessage, "blah")
        XCTAssertNotNil(pEpMessage.longMessage)

        let theAttachments = pEpMessage.attachments ?? []
        XCTAssertEqual(theAttachments.count, 2)
        for i in 0..<theAttachments.count {
            let theAttachment = theAttachments[i]
            if i == 0 {
                XCTAssertEqual(theAttachment.mimeType, "image/jpeg")
            } else if i == 1 {
                XCTAssertEqual(theAttachment.mimeType, "text/plain")
            }
        }
    }
}
