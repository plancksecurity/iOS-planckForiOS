//
//  MailParsingTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 17.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PEPObjCAdapterFramework

class MailParsingTests: PersistentStoreDrivenTestBase {
    var fromIdent: PEPIdentity!

    override func setUp() {
        super.setUp()

        let cdMyAccount = SecretTestData().createWorkingCdAccount(context: moc, number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder(context: moc)
        cdInbox.name = ImapConnection.defaultInboxName
        cdInbox.account = cdMyAccount
        moc.saveAndLogErrors()

        cdAccount = cdMyAccount
    }
}
