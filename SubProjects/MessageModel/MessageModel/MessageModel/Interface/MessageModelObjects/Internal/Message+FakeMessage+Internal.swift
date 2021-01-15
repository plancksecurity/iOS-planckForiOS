//
//  Message+FakeMessage+Internal.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Internal code related to fake messages.
extension Message {
    var isFakeMessage: Bool {
        return cdObject.isFakeMessage
    }

    /// Does not save!!
    @discardableResult
    func createFakeMessage(in targetFolder: Folder) -> Message {
        let cdFakeMsg =  cdObject.createFakeMessage(context: moc)
        cdFakeMsg.parent = targetFolder.cdObject
        cdFakeMsg.targetFolder = nil
        let fakeMsg = Message(cdObject: cdFakeMsg, context: moc)
        return fakeMsg
    }

    private convenience init(uid: Int, message: Message, parentFolder: Folder) {
        self.init(uid: uid, message: message)
        self.parent = parentFolder
    }
}
