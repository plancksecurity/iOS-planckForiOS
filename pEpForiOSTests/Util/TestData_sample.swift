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
    func populateAccounts() {
        // An example account
        testAccounts.append(AccountSettings(
            accountName: "A second account",
            idAddress: "email2@example.com",
            idUserName: "User Name 2",

            imapServerAddress: "mail.example.com",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.tls,
            imapServerPort: 993,

            smtpServerAddress: "mail.example.com",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.tls,
            smtpServerPort: 587,

            password: "someFurtherPassword"))
    }
}
