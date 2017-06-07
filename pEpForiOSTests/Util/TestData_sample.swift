//
//  TestDataImpl.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class TestData: TestDataBase {
    override func populateAccounts() {
        append(accountSettings: AccountSettings(
            accountName: "Whatever",
            idAddress: "someone@example.com",
            idUserName: "User Name",

            imapServerAddress: "imap.example.com",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.tls,
            imapServerPort: 993,

            smtpServerAddress: "smtp.example.com",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.startTls,
            smtpServerPort: 587,

            password: "some secret password"))
    }
}
