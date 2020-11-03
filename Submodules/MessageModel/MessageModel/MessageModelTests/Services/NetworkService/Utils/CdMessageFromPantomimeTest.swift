//
//  CdMessageFromPantomimeTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 16.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

import PantomimeFramework
@testable import MessageModel

class CdMessageFromPantomimeTest: PersistentStoreDrivenTestBase {
    /// Tests that a certain in-reply-to will trigger setting the auto-consume header
    /// when converting from CWIMAPMessage to CdMessage, even though there was no
    /// actual auto-consume header in the original.
    func testCdMessageFromPantimomeAutoConsumeInReplyTo() {
        let cwInbox = CWFolder(name: ImapConnection.defaultInboxName)
        let cwMessage = CWIMAPMessage()
        cwMessage.setFolder(cwInbox)
        cwMessage.setInReplyTo(CdMessage.inReplyToAutoConsume)
        let modus = CWMessageUpdate()
        modus.rfc822 = true
        guard let cdMsg = CdMessage.insertOrUpdate(pantomimeMessage: cwMessage,
                                                   account: cdAccount,
                                                   messageUpdate: modus,
                                                   context: moc) else {
                                                    XCTFail()
                                                    return
        }
        XCTAssertTrue(cdMsg.isAutoConsumable)
    }
}
