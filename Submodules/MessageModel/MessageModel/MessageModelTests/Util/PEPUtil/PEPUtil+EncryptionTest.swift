//
//  EncryptionTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 13.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import PEPObjCAdapterFramework
@testable import MessageModel

class EncryptionTests: XCTestCase {
    func testPassiveMode() {
        testPassiveModeHelper(enablePassiveMode: false)
        testPassiveModeHelper(enablePassiveMode: true)
    }

    func testPassiveModeHelper(enablePassiveMode: Bool) {
        PEPObjCAdapter.setPassiveModeEnabled(enablePassiveMode)

        var me = PEPIdentity(address: "own@example.com",
                             userID: "my_user_id",
                             userName: "My Username",
                             isOwn: true)
        let recipient = PEPIdentity(address: "recipient@example.com",
                                    userID: "partner_user_id",
                                    userName: "Another Username",
                                    isOwn: false)
        me = mySelf(for: me)
        let msg = PEPMessage()
        msg.direction = .outgoing
        msg.from = me
        msg.to = [recipient]
        msg.shortMessage = "subject: whatever"
        msg.longMessage = "text: whatever"
        var theEncryptedMessage: PEPMessage?

        let exp = expectation(description: "exp")
        PEPUtils.encrypt(pEpMessage: msg, errorCallback: { (_) in
            XCTFail()
        }) { (_, encryptedMessage) in
            theEncryptedMessage = encryptedMessage
            exp.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        guard let encryptedMesage = theEncryptedMessage else {
            XCTFail()
            return
        }
        let attachments = encryptedMesage.attachments ?? []

        if enablePassiveMode {
            XCTAssertEqual(attachments.count, 0)
        } else {
            XCTAssertEqual(attachments.count, 1)
        }
    }
}

