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

    func testSortOutUnencryptedReceiversForPEPMail() {
        let session = PEPSession.init()

        let identity: NSMutableDictionary = [:]
        identity[kPepUsername] = "myself"
        identity[kPepAddress] = "somewhere@overtherainbow.com"
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let receiver1: NSMutableDictionary = [:]
        receiver1[kPepUsername] = "receiver1"
        receiver1[kPepAddress] = "receiver1@shopsmart.com"

        let receiver2: NSMutableDictionary = [:]
        receiver2[kPepUsername] = "receiver2"
        receiver2[kPepAddress] = "receiver2@shopsmart.com"

        let receiver3: NSMutableDictionary = [:]
        receiver3[kPepUsername] = "receiver3"
        receiver3[kPepAddress] = "receiver3@shopsmart.com"

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity, receiver1]
        pepMail[kPepCC] = [identity, receiver2]
        pepMail[kPepBCC] = [identity, receiver3]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (unencryptedReceivers, encryptedBCC, pepMailPurged)
            = session.filterOutSpecialReceiversForPEPMail(pepMail)
        XCTAssertEqual(unencryptedReceivers,
                       [PEPSession.PEPRecipient.init(recipient: receiver1, recipientType: .To),
                        PEPSession.PEPRecipient.init(recipient: receiver2, recipientType: .CC),
                        PEPSession.PEPRecipient.init(recipient: receiver3, recipientType: .BCC)])
        XCTAssertEqual(encryptedBCC,
                       [PEPSession.PEPRecipient.init(recipient: identity, recipientType: .BCC)])
        XCTAssertEqual(pepMailPurged[kPepTo]
            as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepCC] as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepBCC] as? NSArray, NSArray.init(array: []))
    }
}
