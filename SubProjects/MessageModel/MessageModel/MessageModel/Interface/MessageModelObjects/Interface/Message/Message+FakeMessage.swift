//
//  Message+FakeMessage.swift
//  pEp
//
//  Created by Andreas Buff on 10.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

/// Public code related to fake messages.
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

    static public func saveForAppend(msg: Message) {
        let moc: NSManagedObjectContext = msg.session.moc

        let newUuid = MessageID.generateUUID()

        let appendee = msg.cdObject
        appendee.uid = Int32(CdMessage.uidNeedsAppend)
        appendee.uuid = newUuid

        let _ = msg.cdObject.createFakeMessage(context: moc)

        moc.saveAndLogErrors()
    }
}
