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

        let cdMyAccount = TestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdMyAccount

        TestUtil.skipValidation()
        Record.saveAndWait()

        cdOwnAccount = cdMyAccount

        decryptedMessageSetup()
    }

    override func tearDown() {
        PEPSession.cleanup()
        super.tearDown()
    }

    func decryptedMessageSetup() {
        let me = PEPIdentity(address: "iostest002@peptest.ch", userID: "userID",
                             userName: "User Name", isOwn:true)
        let session = PEPSession()
        session.update(me)
        XCTAssertNotNil(me.fingerPrint)

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "HandshakeTests_mail_001.txt",
            cdOwnAccount: cdOwnAccount) else {
                XCTFail()
                return
        }

        let pEpMessage = cdMessage.pEpMessageDict()

        guard let optFields = pEpMessage[kPepOptFields] as? [[String]] else {
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

        var pEpDecryptedMessage: NSDictionary? = nil
        var keys: NSArray?
        let rating = session.decryptMessageDict(pEpMessage, dest: &pEpDecryptedMessage, keys: &keys)
        XCTAssertEqual(rating, PEP_rating_unencrypted)

        guard let theMessage = pEpDecryptedMessage else {
            XCTFail("expected message decrypt to work")
            return
        }

        guard let pEpFrom = theMessage[kPepFrom] as? PEPIdentity else {
            XCTFail("expected from in message")
            return
        }
        self.fromIdent = pEpFrom
    }

    func testPositiveTrustResetCycle() {
        let session = PEPSession()
        session.update(fromIdent)
        XCTAssertNotNil(fromIdent.fingerPrint)
        XCTAssertFalse(fromIdent.containsPGPCommType())

        session.trustPersonalKey(fromIdent)
        XCTAssertFalse(fromIdent.containsPGPCommType())

        session.keyResetTrust(fromIdent)
        XCTAssertFalse(fromIdent.containsPGPCommType())

        session.trustPersonalKey(fromIdent)
        XCTAssertFalse(fromIdent.containsPGPCommType())

        session.keyResetTrust(fromIdent)
        XCTAssertFalse(fromIdent.containsPGPCommType())
    }

    func testNegativeTrustResetCycle() {
        let session = PEPSession()
        session.update(fromIdent)
        XCTAssertNotNil(fromIdent.fingerPrint)
        XCTAssertFalse(fromIdent.containsPGPCommType())

        session.keyMistrusted(fromIdent)
        XCTAssertFalse(fromIdent.containsPGPCommType())

        // after mistrust, the engine throws away all status,
        // so this is expected behavior. See ENGINE-254
        session.keyResetTrust(fromIdent)
        XCTAssertTrue(fromIdent.containsPGPCommType())
    }
}
