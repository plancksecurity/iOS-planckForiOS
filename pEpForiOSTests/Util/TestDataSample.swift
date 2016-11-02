//
//  TestDataSample.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class TestDataSample {
    /**
     An account that should not be able to be verified.
     */
    func createDisfunctionalAccount() -> Account {
        let id = Identity.create(address: "user1@example.com", userName: "User 1",
                                 userID: "user1")
        let smtp = Server.create(serverType: .smtp, port: 4096, address: "localhost",
                                 transport: .plain)
        let imap = Server.create(serverType: .imap, port: 4097, address: "localhost",
                                 transport: .plain)
        let cred = ServerCredentials.create(userName: id.address, password: "password",
                                            servers: [smtp, imap])
        let acc = Account.create(identity: id, credentials: [cred])
        return acc
    }

    /**
     This won't work.
     Extend this TestData.swift (same folder), which is not checked in.
     */
    func createWorkingAccount() -> Account {
        return createDisfunctionalAccount()
    }
}
