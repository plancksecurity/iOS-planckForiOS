//
//  Message+Stub.swift
//  pEp
//
//  Created by Borja González de Pablo on 11/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension Message {
    // Duplicates fakeMessage in pEp4IOSTests
    static public func fakeMessage(uuid: MessageID, uid: UInt = 0, folder: Folder) -> Message {
     //   let message:Message = DispatchQueue.main.sync {
            let account = Account.by(address: "iostest006@peptest.ch")!
            let message = Message(uuid: uuid, uid: uid, parentFolder: folder)
            message.comments = "comment"
            message.shortMessage = "short message"
            message.longMessage = "long message"
            message.longMessageFormatted = "long message"
            message.from = account.user
            message.to = [account.user]
            message.cc = [account.user]
            message.parent = Folder.by(account: account, folderType: .inbox)!
            message.sent = Date()
            message.received = Date()
            message.replyTo = [account.user]
            message.references = ["ref1"]
        //    message.save()

            return message
       // }
       /// return message
    }
}
