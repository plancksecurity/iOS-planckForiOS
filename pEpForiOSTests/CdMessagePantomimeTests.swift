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
    
    override func setUp() {
        super.setUp()
        let _ = PersistentSetup()
    }
    
    func testInsertOrUpdatePantomimeMessage() {
        let account = TestData().createWorkingAccount()
        account.save()

        guard let cdAccount: MessageModel.CdAccount = CdAccount.first(
            with: "identity.address", value: "unittest.ios.4@peptest.ch") else {
                XCTAssertTrue(false)
                return
        }

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName

        guard let data = TestUtil.loadDataWithFileName("UnencryptedHTMLMail.txt") else {
            XCTAssertTrue(false)
            return
        }
        let message = CWIMAPMessage.init(data: data)
        message.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))
        let msg = CdMessagePantomime.insertOrUpdate(
            pantomimeMessage: message, account: cdAccount, forceParseAttachments: true)
        XCTAssertNotNil(msg)
        if let m = msg {
            XCTAssertNotNil(m.longMessage)
            XCTAssertNotNil(m.longMessageFormatted)
        }
    }
}
