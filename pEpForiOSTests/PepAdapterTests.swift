//
//  PepAdapterTests.swift
//  pEpForiOS
//
//  Created by hernani on 03/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class PepAdapterTests: XCTestCase {
    let comp = "PepAdapterTests"
    let identity_me: NSMutableDictionary = [kPepAddress: "some@mail.com",
                                            kPepUsername: "This is me"]
    var pEpSession: PEPSession!
    
    override func setUp() {
        super.setUp()
        XCTAssertTrue(PEPUtil.pEpClean())
        pEpSession = PEPSessionCreator.shared.newSession()
    }
    
    override func tearDown() {
        pEpSession = nil
        super.tearDown()
    }

    func testPepSession() {
        XCTAssertNotNil(pEpSession)
    }
    
    func testMyself() {
        // This includes that a new key is generated.
        pEpSession.mySelf(identity_me)
        XCTAssertNotNil(identity_me[kPepUserID])
    }
    
    /**
     - See: https://cacert.pep.foundation/jira/browse/IOSAD-10
     https://cacert.pep.foundation/jira/browse/ENGINE-159
     */
    func testDecryptMessageWithoutAttachments() {
        let pepMessage: PEPMessage = [
            kPepAttachments: NSArray(),
            kPepTo: NSArray(array: [identity_me]),
            kPepFrom: identity_me,
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
