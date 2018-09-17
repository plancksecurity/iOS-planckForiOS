//
//  HandshakeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class HandshakeTests: XCTestCase {
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

        decryptedMessageSetup(pEpMySelfIdentity: cdMyAccount.pEpIdentity())
    }

    override func tearDown() {
        PEPSession.cleanup()
        super.tearDown()
    }

    func decryptedMessageSetup(pEpMySelfIdentity: PEPIdentity) {
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
        XCTAssertEqual(theAttachments.count, 1)
        XCTAssertEqual(theAttachments[0].mimeType, "application/pgp-keys")

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
        var rating = PEP_rating_undefined
        let theMessage = try! session.decryptMessage(pEpMessage,
                                                     flags: nil,
                                                     rating: &rating,
                                                     extraKeys: &keys,
                                                     status: nil)
        XCTAssertEqual(rating, PEP_rating_unencrypted)

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

//    func testNegativeTrustResetCycle() {
//        let session = PEPSession()
//        try! session.update(fromIdent)
//        XCTAssertNotNil(fromIdent.fingerPrint)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        let fromIdentCopy = PEPIdentity(identity: fromIdent)
//        try! session.keyMistrusted(fromIdent)
//        try! session.update(fromIdent)
//        XCTAssertNil(fromIdent.fingerPrint)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        // After mistrust, the engine now still remebers pEp status. See ENGINE-254.
//        try! session.undoLastMistrust()
//        try! session.update(fromIdentCopy)
//        XCTAssertTrue(try! session.isPEPUser(fromIdentCopy).boolValue)
//    }
//
    func testRestTruestOnYellowIdentity() {
        let session = PEPSession()
        try! session.update(fromIdent)
        XCTAssertNotNil(fromIdent.fingerPrint)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        var numRating = try! session.rating(for: fromIdent)
        XCTAssertEqual(numRating.pEpRating, PEP_rating_reliable)

        try! session.keyResetTrust(fromIdent)
        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)

        numRating = try! session.rating(for: fromIdent)
        XCTAssertEqual(numRating.pEpRating, PEP_rating_reliable)
    }
}
