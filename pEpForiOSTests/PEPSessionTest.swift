//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class PEPSessionTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testFilterOutUnencryptedReceiversForPEPMail() {
        let session = PEPSession.init()
        let (identity, receiver1, receiver2, receiver3, _) = TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        var pepMail = PEPMail()
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = NSArray.init(array: [identity, receiver1])
        pepMail[kPepCC] = NSArray.init(array: [identity, receiver2])
        pepMail[kPepBCC] = NSArray.init(array: [identity, receiver3])
        pepMail[kPepShortMessage] = "Subject" as AnyObject
        pepMail[kPepLongMessage] = "Some body text" as AnyObject

        let (unencryptedReceivers, encryptedBCC, pepMailPurged)
            = session.filterOutSpecialReceiversForPEPMail(pepMail as PEPMail)
        XCTAssertEqual(unencryptedReceivers,
                       [PEPRecipient.init(recipient: receiver1, recipientType: .to),
                        PEPRecipient.init(recipient: receiver2, recipientType: .cc),
                        PEPRecipient.init(recipient: receiver3, recipientType: .bcc)])
        XCTAssertEqual(encryptedBCC,
                       [PEPRecipient.init(recipient: identity as NSDictionary as! PEPContact,
                                          recipientType: .bcc)])
        XCTAssertEqual(pepMailPurged[kPepTo]
            as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepCC] as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepBCC] as? NSArray, NSArray.init(array: []))
    }

    func testPEPMailBuckets() {
        let session = PEPSession.init()
        let (identity, receiver1, receiver2, receiver3, _) = TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        var pepMail = PEPMail()
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = NSArray.init(array: [identity, receiver1])
        pepMail[kPepCC] = NSArray.init(array: [identity, receiver2])
        pepMail[kPepBCC] = NSArray.init(array: [identity, receiver3])
        pepMail[kPepShortMessage] = "Subject" as AnyObject
        pepMail[kPepLongMessage] = "Some body text" as AnyObject

        let (encrypted, unencrypted) = session.bucketsForPEPMail(pepMail as PEPMail)
        XCTAssertEqual(encrypted.count, 2)
        XCTAssertEqual(unencrypted.count, 1)

        XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
        XCTAssertEqual(encrypted[0][kPepCC] as? NSArray, [identity])
        XCTAssertEqual(encrypted[0][kPepBCC] as? NSArray, [])

        XCTAssertEqual(encrypted[1][kPepTo] as? NSArray, [])
        XCTAssertEqual(encrypted[1][kPepCC] as? NSArray, [])
        XCTAssertEqual(encrypted[1][kPepBCC] as? NSArray, [identity])

        XCTAssertEqual(unencrypted[0][kPepTo] as? NSArray, [receiver1])
        XCTAssertEqual(unencrypted[0][kPepCC] as? NSArray, [receiver2])
        XCTAssertEqual(unencrypted[0][kPepBCC] as? NSArray, [receiver3])
    }

    func testPEPMailBucketsWithSingleEncryptedMail() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (encrypted, unencrypted) = session.bucketsForPEPMail(
            pepMail as NSDictionary as! PEPMail)
        XCTAssertEqual(encrypted.count, 1)
        XCTAssertEqual(unencrypted.count, 0)

        XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
        XCTAssertNil(encrypted[0][kPepCC])
        XCTAssertNil(encrypted[0][kPepBCC])
    }

    func testPEPMailBuckets2() {
        let session = PEPSession.init()

        // Import public key for receiver4
        TestUtil.importKeyByFileName(
            session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        let (identity, receiver1, receiver2, receiver3, receiver4) =
            TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity, receiver1]
        pepMail[kPepCC] = [identity, receiver2]
        pepMail[kPepBCC] = [identity, receiver3, receiver4]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (encrypted, unencrypted) = session.bucketsForPEPMail(
            pepMail as NSDictionary as! PEPMail)
        XCTAssertEqual(encrypted.count, 3)
        XCTAssertEqual(unencrypted.count, 1)

        if encrypted.count == 3 {
            XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
            XCTAssertEqual(encrypted[0][kPepCC] as? NSArray, [identity])
            XCTAssertEqual(encrypted[0][kPepBCC] as? NSArray, [])

            XCTAssertEqual(encrypted[1][kPepTo] as? NSArray, [])
            XCTAssertEqual(encrypted[1][kPepCC] as? NSArray, [])
            XCTAssertEqual(encrypted[1][kPepBCC] as? NSArray, [identity])

            XCTAssertEqual(encrypted[2][kPepTo] as? NSArray, [])
            XCTAssertEqual(encrypted[2][kPepCC] as? NSArray, [])
            XCTAssertEqual(encrypted[2][kPepBCC] as? NSArray, [receiver4])
        }

        XCTAssertEqual(unencrypted[0][kPepTo] as? NSArray, [receiver1])
        XCTAssertEqual(unencrypted[0][kPepCC] as? NSArray, [receiver2])
        XCTAssertEqual(unencrypted[0][kPepBCC] as? NSArray, [receiver3])
    }
}
