//
//  HandshakeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework
// Must be moved to MM.
//class HandshakeTests: CoreDataDrivenTestBase {
//    var fromIdent: PEPIdentity!
//
//    override func setUp() {
//        super.setUp()
//
//        cdAccount.identity?.userName = "iOS Test 002"
//        cdAccount.identity?.userID = "iostest002@peptest.ch_ID"
//        cdAccount.identity?.address = "iostest002@peptest.ch"
//
//        let cdInbox = CdFolder(context: moc)
//        cdInbox.name = ImapConnection.defaultInboxName
//        cdInbox.account = cdAccount
//        moc.saveAndLogErrors()
//
//        decryptedMessageSetup(pEpMySelfIdentity: cdAccount.pEpIdentity())
//    }
//
//    func decryptedMessageSetup(pEpMySelfIdentity: PEPIdentity) {
//        pEpMySelfIdentity = mySelf(for: pEpMySelfIdentity)
//        // Must be moved to MM.
//        XCTAssertNotNil(pEpMySelfIdentity.fingerPrint)
//
//        guard let cdMessage = TestUtil.cdMessage(fileName: "HandshakeTests_mail_001.txt",
//                                                 cdOwnAccount: cdAccount) else {
//                                                    XCTFail()
//                                                    return
//        }
//
//        let pEpMessage = cdMessage.pEpMessage(outgoing: true)
//
//        let theAttachments = pEpMessage.attachments ?? []
//        XCTAssertEqual(theAttachments.count, 1)
//        XCTAssertEqual(theAttachments[0].mimeType, ContentTypeUtils.ContentType.pgpKeys)
//
//        guard let optFields = pEpMessage.optionalFields else {
//            XCTFail("expected optional_fields to be defined")
//            return
//        }
//        var foundXpEpVersion = false
//        for innerArray in optFields {
//            if innerArray.count == 2 {
//                if innerArray[0] == "X-pEp-Version" {
//                    foundXpEpVersion = true
//                }
//            } else {
//                XCTFail("corrupt optional fields element")
//            }
//        }
//        XCTAssertTrue(foundXpEpVersion)
//
//        var rating = PEPRating.undefined
//        var testee: PEPMessage?
//
//        let exp = expectation(description: "exp")
//        PEPAsyncSession().decryptMessage(pEpMessage, flags: .none, extraKeys: nil, errorCallback: { (error) in
//            XCTFail(error.localizedDescription)
//            exp.fulfill()
//        }) { (_, pEpDecrypted, _, pEpRating, _) in
//            testee = pEpDecrypted
//            rating = pEpRating
//            exp.fulfill()
//        }
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        XCTAssertEqual(rating, .unencrypted)
//        guard let pEpFrom = testee?.from else {
//            XCTFail("expected from in message")
//            return
//        }
//        self.fromIdent = pEpFrom
//    }
//
//    func testPositiveTrustResetCycle() {
//        let session = PEPSession()
//        try! session.update(fromIdent)
//        XCTAssertNotNil(fromIdent.fingerPrint)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        try! session.trustPersonalKey(fromIdent)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        try! session.keyResetTrust(fromIdent)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        try! session.trustPersonalKey(fromIdent)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        try! session.keyResetTrust(fromIdent)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//    }
//
//    func testNegativeTrustResetCycle() {
//        let session = PEPSession()
//
//        try! session.update(fromIdent)
//        XCTAssertNotNil(fromIdent.fingerPrint)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//
//        try! session.keyMistrusted(fromIdent)
//        try! session.update(fromIdent)
//        XCTAssertNil(fromIdent.fingerPrint)
//        XCTAssertTrue(try! session.isPEPUser(fromIdent).boolValue)
//    }
//
//    func testRestTruestOnYellowIdentity() {
//        let session = PEPSession()
//        try! session.update(fromIdent)
//        XCTAssertNotNil(fromIdent.fingerPrint)
//        XCTAssertTrue((try? session.isPEPUser(fromIdent).boolValue) ?? false)
//
//        do {
//            var pEpRating = rating(forPepIdentity: fromIdent)
//            XCTAssertEqual(pEpRating, .reliable)
//            XCTAssertNoThrow(try session.keyResetTrust(fromIdent))
//            let isPepUser = try session.isPEPUser(fromIdent).boolValue
//            XCTAssertTrue(isPepUser)
//            pEpRating = rating(forPepIdentity: fromIdent)
//            XCTAssertEqual(pEpRating, .reliable)
//        } catch {
//            XCTFail()
//        }
//    }
//}
//
//// MARK: - HELPER
//
//extension HandshakeTests {
//    private func rating(forPepIdentity identity: PEPIdentity) -> PEPRating {
//        var pEpRating: PEPRating? = nil
//        let exp = expectation(description: "exp")
//        PEPAsyncSession().rating(for: fromIdent, errorCallback: { (_) in
//            XCTFail()
//            exp.fulfill()
//        }) { (rating) in
//            pEpRating = rating
//            exp.fulfill()
//        }
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        guard let rating = pEpRating else {
//            XCTFail()
//            return .undefined
//        }
//        return rating
//    }
//}
