//
//  MockData.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class MockData {
    static func insertData() {
        let ident = Identity.create(address: "this_is_me@blah.org", userName: "User 1",
                                    userID: nil)
        let imapServer = Server.create(
            serverType: .imap, port: 918, address: "mail.yahoo.com", userName: "user1",
            transport: .tls)
        let smtpServer = Server.create(
            serverType: .imap, port: 587, address: "mail.yahoo.com", userName: "user1",
            transport: .startTls)
        let _ = Account.create(user: ident, servers: [imapServer, smtpServer])
    }

}
