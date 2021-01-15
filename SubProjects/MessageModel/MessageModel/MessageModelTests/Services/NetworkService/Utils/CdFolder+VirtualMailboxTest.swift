//
//  CdFolder+VirtualMailboxTest.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 19.07.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

class CdFolder_VirtualMailboxTest: PersistentStoreDrivenTestBase {

    func testShouldNotAppendMessages() {
        cdAccount.identity?.address = "someone@gmail.com"
        cdAccount.server(type: .imap)?.address = "imap.google.com"
        cdAccount.server(type: .smtp)?.address = "smtp.google.com"
        moc.saveAndLogErrors()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail("No Inbox")
            return
        }
        XCTAssertFalse(inbox.shouldNotAppendMessages)
    }
}
