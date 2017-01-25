//
//  CdMessagePantomimeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 09/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class CdMessagePantomimeTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    func testInsertOrUpdatePantomimeMessage() {
        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName

        guard let data = TestUtil.loadDataWithFileName("UnencryptedHTMLMail.txt") else {
            XCTAssertTrue(false)
            return
        }
        let message = CWIMAPMessage.init(data: data)
        message.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))
        let msg = CdMessage.insertOrUpdate(
            pantomimeMessage: message, account: cdAccount, messageUpdate: CWMessageUpdate(),
            forceParseAttachments: true)
        XCTAssertNotNil(msg)
        if let m = msg {
            XCTAssertNotNil(m.longMessage)
            XCTAssertNotNil(m.longMessageFormatted)
        }
    }
}
