//
//  MockData.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

open class MockData {
    
    static func insertData() {
        let ident = Identity.create(address: "this_is_me@blah.org", userName: "User 1")
        let imapServer = Server.create(
            serverType: .imap, port: 918, address: "mail.yahoo.com",
            transport: .tls)
        let smtpServer = Server.create(
            serverType: .imap, port: 587, address: "mail.yahoo.com",
            transport: .startTls)
        let credentials = ServerCredentials.create(userName: "username",
                                                   servers: [imapServer, smtpServer])
        let account = Account.create(identity: ident, credentials: [credentials])
        insertRootFolders(account: account)
    }

    static func insertRootFolders(account: Account) {
        for (name, folderType) in
            [("INBOX", FolderType.inbox), ("Drafts", FolderType.drafts),
             ("Outbox", FolderType.localOutbox)] {
                let folder = Folder.createRootFolder(
                    name: name, uuid: UUID.generate(), account: account)
                folder.folderType = folderType
                insertMessages(folder: folder)
        }
    }

    static func insertMessages(folder: Folder) {
        for i in 1...10 {
            let msg = Message.create(uuid: UUID.generate())
            msg.shortMessage = "Test \(i)"
            msg.from = Identity.create(address: "igor.vojinovic@appculture.com")
            msg.to = [Identity.create(address: "igor.vojinovic@appculture.com")]
            msg.longMessage = "<html><head></head><body>Test Message Nr: \(i) </body></html>"
            msg.sent = Date() as NSDate?
            folder.add(message: msg)
        }
    }
    
    static func createFolder(_ account: Account) -> Folder {
        let f = Folder.createRootFolder(name: "pEpSi", uuid: UUID.generate(), account: account)
        f.folderType = .normal
        MockData.insertMessages(folder: f)
        return f
    }
}
