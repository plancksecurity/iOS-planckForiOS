//
//  HandshakeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework

class HandshakeTests: PersistentStoreDrivenTestBase {
    var fromIdent: PEPIdentity!

    override func setUp() {
        super.setUp()

        cdAccount.identity?.userName = "iOS Test 002"
        cdAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder(context: moc)
        cdInbox.name = ImapConnection.defaultInboxName
        cdInbox.account = cdAccount
        moc.saveAndLogErrors()

        guard let accountId = cdAccount.identity else {
            XCTFail()
            return
        }
        decryptedMessageSetup(pEpMySelfIdentity: accountId.pEpIdentity())
    }

    func decryptedMessageSetup(pEpMySelfIdentity: PEPIdentity) {
        let session = PEPSession()
        try! session.mySelf(pEpMySelfIdentity)
        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)

        guard let cdMessage = TestUtil.cdMessage(testClass: HandshakeTests.self,
                                                 fileName: "HandshakeTests_mail_001.txt",
                                                 cdOwnAccount: cdAccount) else {
                                                    XCTFail()
                                                    return
        }

        let pEpMessage = cdMessage.pEpMessage(outgoing: true)

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

        var keys: NSArray?
        var rating = PEPRating.undefined
        let theMessage = try! session.decryptMessage(pEpMessage,
                                                     flags: nil,
                                                     rating: &rating,
                                                     extraKeys: &keys,
                                                     status: nil)
        XCTAssertEqual(rating, .unencrypted)

        guard let pEpFrom = theMessage.from else {
            XCTFail("expected from in message")
            return
        }
        self.fromIdent = pEpFrom
    }

    func testPositiveTrustResetCycle() {
        let session = PEPSession()
        try! session.update(fromIdent)
        XCTAssertNotNil(fromIdent.fingerPrint)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        try! session.trustPersonalKey(fromIdent)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        try! session.keyResetTrust(fromIdent)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        try! session.trustPersonalKey(fromIdent)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        try! session.keyResetTrust(fromIdent)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
    }

    func testNegativeTrustResetCycle() {
        let session = PEPSession()

        try! session.update(fromIdent)
        XCTAssertNotNil(fromIdent.fingerPrint)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        try! session.keyMistrusted(fromIdent)
        try! session.update(fromIdent)
        XCTAssertNil(fromIdent.fingerPrint)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
    }

    func testRestTruestOnYellowIdentity() {
        let session = PEPSession()
        try! session.update(fromIdent)
        XCTAssertNotNil(fromIdent.fingerPrint)
        XCTAssertTrue((try? session.isPEPUser(fromIdent).boolValue) ?? false)

        do {
            var numRating =  try! session.rating(for: fromIdent)
            XCTAssertEqual(numRating.pEpRating, .reliable)
            XCTAssertNoThrow(try session.keyResetTrust(fromIdent))
            let isPepUser = try session.isPEPUser(fromIdent).boolValue
            XCTAssertTrue(isPepUser)
            numRating = try session.rating(for: fromIdent)
            XCTAssertEqual(numRating.pEpRating, .reliable)
        } catch {
            XCTFail()
        }
    }
}
