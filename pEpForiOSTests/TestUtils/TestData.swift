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
 /*
        //#########
        //# BUFFHALTESTELLE #
        append(accountSettings: AccountSettings(
            accountName: "buffStop pEp test",
            idAddress: "peptest@buffhaltestelle.de",
            idUserName: "peptest@buffhaltestelle.d",

            imapServerAddress: "mail.buffhaltestelle.de",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.startTls,
            imapServerPort: 143,

            smtpServerAddress: "smtp.buffhaltestelle.de",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.startTls,
            smtpServerPort: 25,

            password: "noDichAuf"))

        //#########
        //# YAHOO #
        append(accountSettings: AccountSettings(
            accountName: "yahoo test",
            idAddress: "peptest002@yahoo.com",
            idUserName: "peptest002@yahoo.com",

            imapServerAddress: "imap.mail.yahoo.com",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.tls,
            imapServerPort: 993,

            smtpServerAddress: "smtp.mail.yahoo.com",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.startTls,
            smtpServerPort: 587,

            password: "noDichAuf"))
*/

        //#########
        //# 005 #
        append(accountSettings: AccountSettings(
            accountName: "iostest005",
            idAddress: "iostest005@peptest.ch",
            idUserName: "iostest005@peptest.ch",

            imapServerAddress: "peptest.ch",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.tls,
            imapServerPort: 993,

            smtpServerAddress: "peptest.ch",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.startTls,
            smtpServerPort: 587,

            password: "pEpdichauf"))
        
        //#########
        //# 004 #
        append(accountSettings: AccountSettings(
            accountName: "iostest004",
            idAddress: "iostest004@peptest.ch",
            idUserName: "iostest004@peptest.ch",

            imapServerAddress: "peptest.ch",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.tls,
            imapServerPort: 993,

            smtpServerAddress: "peptest.ch",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.startTls,
            smtpServerPort: 587,

            password: "pEpdichauf"))
        // etc.
    }
}
