//
//  PepAdapterTests.swift
//  pEpForiOS
//
//  Created by hernani on 03/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
@testable import pEpForiOS

class PepAdapterTests: XCTestCase {
    let comp = "PepAdapterTests"
    let identityMe = PEPIdentity(address: "some@mail.com", userID: CdIdentity.pEpOwnUserID, userName: "This is me",
                                 isOwn: true)

    var pEpSession: PEPSession {
        return PEPSession()
    }
    
    override func setUp() {
        super.setUp()
        XCTAssertTrue(PEPUtil.pEpClean())
    }
    
    override func tearDown() {
        PEPSession.cleanup()
        super.tearDown()
    }

    func testPepSession() {
        XCTAssertNotNil(pEpSession)
    }
    
    func testMyself() {
        let userID = identityMe.userID
        // This includes that a new key is generated.
        pEpSession.mySelf(identityMe)
        XCTAssertEqual(identityMe.userID, userID)
    }
    
    /**
     - See: https://cacert.pep.foundation/jira/browse/IOSAD-10
     https://cacert.pep.foundation/jira/browse/ENGINE-159
     */
    func testDecryptMessageWithoutAttachments() {
        let pepMessage: PEPMessageDict = [
            kPepAttachments: NSArray(),
            kPepTo: NSArray(array: [identityMe]),
            kPepFrom: identityMe,
            kPepShortMessage: "Subject" as NSString,
            kPepLongMessage: "Long long message" as NSString
        ]
        var pepDecryptedMessage: NSDictionary? = nil
        var keys: NSArray?
        let color = pEpSession.decryptMessageDict(
            pepMessage, dest: &pepDecryptedMessage, keys: &keys)
        XCTAssertEqual(color, PEP_rating_unencrypted)
    }
}
