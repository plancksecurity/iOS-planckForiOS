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
import PEPObjCAdapterFramework

class PepAdapterTests: XCTestCase {
    let comp = "PepAdapterTests"
    let identityMe = PEPIdentity(address: "some@mail.com",
                                 userID: CdIdentity.pEpOwnUserID,
                                 userName: "This is me",
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
        try! pEpSession.mySelf(identityMe)
        XCTAssertEqual(identityMe.userID, userID)
    }
    
    /**
     - See: https://cacert.pep.foundation/jira/browse/IOSAD-10
     https://cacert.pep.foundation/jira/browse/ENGINE-159
     */
    func testDecryptMessageWithoutAttachments() {
        let pEpMessage = PEPMessage()
        pEpMessage.to = [identityMe]
        pEpMessage.from = identityMe
        pEpMessage.shortMessage = "Subject"
        pEpMessage.longMessage = "Long Message"

        var keys: NSArray?
        var rating = PEPRating.undefined
        try! pEpSession.decryptMessage(pEpMessage,
                                       flags: nil,
                                       rating: &rating,
                                       extraKeys: &keys,
                                       status: nil)
        XCTAssertEqual(rating, .unencrypted)
    }

    func testIsPEPUser() {
        let ident = PEPIdentity()
        ident.userID = "some_fake_userid"
        XCTAssertThrowsError(try self.pEpSession.isPEPUser(ident))
    }
}
