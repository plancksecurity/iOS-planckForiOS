//
//  Message+TestUtils.swift
//  MessageModel
//
//  Created by Andreas Buff on 28.08.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

@testable import MessageModel
import CoreData

extension Message {
    static public func createTestMessage(uuid: MessageID, uid: Int = 0) -> Message {
        let fakeId = Identity(address: "unifiedInbox@fake.address.com",
                              userID: nil,
                              userName: "fakeName")
        fakeId.session.commit()
        let fakeAccount = Account(user: fakeId, servers: [Server]())
        fakeAccount.session.commit()
        print(Account.all())
        let fakeFolder = Folder(name: "Inbox", parent: nil, uuid: "fakeFolderUUID", account: fakeAccount, folderType: .inbox)
        fakeFolder.session.commit()
        let message = Message(uuid: uuid, uid: uid, parentFolder: fakeFolder)

        return message
    }
}
