//
//  PantomimeFromPEPMessageTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 19.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
import PantomimeFramework
import PEPObjCAdapterFramework

class PantomimeFromPEPMessageTest: PersistentStoreDrivenTestBase {
    func testInReplyToStaysDuringConversion() {
        let pEpMsg = PEPMessage()

        pEpMsg.references = ["a", "b"]
        pEpMsg.inReplyTo = ["c", CdMessage.inReplyToAutoConsume, "d"]

        let cwMsg = CWIMAPMessage(pEpMessage: pEpMsg,
                                  mailboxName: ImapConnection.defaultInboxName)

        XCTAssertEqual(cwMsg.allReferences() as? [String], ["a", "b", "c", "d"])
        XCTAssertEqual(cwMsg.inReplyTo(), CdMessage.inReplyToAutoConsume)
    }
}
