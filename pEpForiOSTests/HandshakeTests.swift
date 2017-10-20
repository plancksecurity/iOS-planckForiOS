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
    var fromDict = NSMutableDictionary()

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())
        persistentSetup = PersistentSetup()

        let cdMyAccount = TestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"
        cdMyAccount.identity?.isMySelf = true

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
        let me: PEPIdentity = [
            kPepUserID: "userID" as AnyObject,
            kPepUsername: "User Name" as AnyObject,
            kPepAddress: "iostest002@peptest.ch" as AnyObject
        ]
        let meDict = NSMutableDictionary(dictionary: me)
        let session = PEPSession()
        session.mySelf(meDict)
        XCTAssertNotNil(meDict[kPepFingerprint])

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "HandshakeTests_mail_001.txt",
            cdOwnAccount: cdOwnAccount) else {
                XCTFail()
                return
        }

        let pEpMessage = cdMessage.pEpMessage()

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
        self.fromDict = NSMutableDictionary(dictionary: pEpFrom)
    }

    func testPositiveTrustResetCycle() {
        let session = PEPSession()
        session.updateIdentity(fromDict)
        XCTAssertNotNil(fromDict[kPepFingerprint])
        XCTAssertFalse(fromDict.containsPGPCommType)

        session.trustPersonalKey(fromDict)
        XCTAssertFalse(fromDict.containsPGPCommType)

        session.keyResetTrust(fromDict)
        XCTAssertFalse(fromDict.containsPGPCommType)

        session.trustPersonalKey(fromDict)
        XCTAssertFalse(fromDict.containsPGPCommType)

        session.keyResetTrust(fromDict)
        XCTAssertFalse(fromDict.containsPGPCommType)
    }

    func testNegativeTrustResetCycle() {
        let session = PEPSession()
        session.updateIdentity(fromDict)
        XCTAssertNotNil(fromDict[kPepFingerprint])
        XCTAssertFalse(fromDict.containsPGPCommType)

        session.keyMistrusted(fromDict)
        XCTAssertFalse(fromDict.containsPGPCommType)

        // after mistrust, the engine throws away all status,
        // so this is expected behavior. See ENGINE-254
        session.keyResetTrust(fromDict)
        XCTAssertTrue(fromDict.containsPGPCommType)
    }
}
