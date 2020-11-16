//
//  Message+FakeMessage+Public.swift
//  pEp
//
//  Created by Andreas Buff on 10.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

/// Code related to fake messages.
///
/// We are saving fake messages locally for messages that take time to sync with server (e.g.
/// when moving a message to another folder). Fake messages are marked with a special UID.
extension Message {

    /// uid for Fake messages, that are created to show to the user until the actual, real message
    /// is fetched from server.
    /// Example:
    /// User deletes a mail and expects this mail to show up in trah folder imedeatelly. Thus we
    /// save a fake message to show to the user until the real message is fetched.
    static public var uidFakeResponsivenes: Int {
        return CdMessage.uidFakeResponsivenes
    }

    var isFakeMessage: Bool {
        return cdObject.isFakeMessage
    }

    static public func saveForAppend(msg: Message) {
        let moc: NSManagedObjectContext = msg.session.moc

        let newUuid = MessageID.generateUUID()

        let appendee = msg.cdObject
        appendee.uid = Int32(CdMessage.uidNeedsAppend)
        appendee.uuid = newUuid

        let _ = msg.cdObject.createFakeMessage(context: moc)

        moc.saveAndLogErrors()
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
