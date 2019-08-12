//
//  CdMessagePEPMessageTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 14.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class CdMessagePEPMessageTests: CoreDataDrivenTestBase {
    func testCdMessageToPEPMessage() {
        let  cdMsg = CdMessage(context: moc)
        cdMsg.from = cdAccount.identity

        let cdReceiver = CdIdentity(context: moc)
        cdReceiver.address = "receiver@example.com"
        cdReceiver.userID = "receiver_user_id"
        cdMsg.to = NSOrderedSet(array: [cdReceiver])

        let pEpReceiver = cdReceiver.pEpIdentity()

        let pEpMsg = PEPUtils.pEp(cdMessage: cdMsg, outgoing: true)

        XCTAssertEqual(pEpMsg.to?[0], pEpReceiver)
    }
}
