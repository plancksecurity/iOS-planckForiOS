//
//  MailParsingTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 17.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PEPObjCAdapterFramework

class MailParsingTests: PersistentStoreDrivenTestBase {
    var fromIdent: PEPIdentity!

    override func setUp() {
        super.setUp()

        let cdMyAccount = SecretTestData().createWorkingCdAccount(context: moc, number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder(context: moc)
        cdInbox.name = ImapConnection.defaultInboxName
        cdInbox.account = cdMyAccount
        moc.saveAndLogErrors()

        cdAccount = cdMyAccount
    }

    // Must be moved to MM.
    //    func testParseUndisplayableHTMLMessage() {
    //        let pEpMySelfIdentity = cdAccount.pEpIdentity()
    //
    //        pEpMySelfIdentity = mySelf(for: pEpMySelfIdentity)
    //        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)
    //
    //        guard let cdMessage = TestUtil.cdMessage(fileName: "Undisplayable_HTML_Message.txt",
    //                                                 cdOwnAccount: cdAccount)
    //            else {
    //                XCTFail()
    //                return
    //        }
    //
    //        let pEpMessage = cdMessage.pEpMessage(outgoing: true)
    //
    //        let theAttachments = pEpMessage.attachments ?? []
    //        XCTAssertEqual(theAttachments.count, 2)
    //        XCTAssertEqual(theAttachments[0].mimeType, "image/jpeg")
    //        XCTAssertEqual(theAttachments[1].mimeType, "image/png")
    //
    //        XCTAssertEqual(pEpMessage.shortMessage, "Sendung von BlahTex BlahBlah AG - zugestellt")
    //        XCTAssertNil(pEpMessage.longMessage)
    //
    //        guard let htmlMessage = pEpMessage.longMessageFormatted else {
    //            XCTFail()
    //            return
    //        }
    //
    //        XCTAssertTrue(htmlMessage.contains("Guten Tag Herr Müller"))
    //        XCTAssertTrue(htmlMessage.contains(find: "Sendungsnummer"))
    //        XCTAssertTrue(htmlMessage.contains(find: "585862075329118547"))
    //    }
}


// Must be moved to MM.
//    /**
//     IOS-1364
//     */
//    func testParseUndisplayedAttachedJpegMessage() {
//        let pEpMySelfIdentity = cdAccount.pEpIdentity()
//        pEpMySelfIdentity = mySelf(for: pEpMySelfIdentity)
//        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)
//
//        guard let cdMessage = TestUtil.cdMessage(fileName: "1364_Mail_missing_attached_image.txt",
//                                                 cdOwnAccount: cdAccount)
//            else {
//                XCTFail()
//                return
//        }
//
//        let pEpMessage = cdMessage.pEpMessage(outgoing: true)
//
//        XCTAssertEqual(pEpMessage.shortMessage, "blah")
//        XCTAssertNotNil(pEpMessage.longMessage)
//
//        let theAttachments = pEpMessage.attachments ?? []
//        XCTAssertEqual(theAttachments.count, 2)
//        for i in 0..<theAttachments.count {
//            let theAttachment = theAttachments[i]
//            if i == 0 {
//                XCTAssertEqual(theAttachment.mimeType, "image/jpeg")
//            } else if i == 1 {
//                XCTAssertEqual(theAttachment.mimeType, "text/plain")
//            }
//        }
//    }
