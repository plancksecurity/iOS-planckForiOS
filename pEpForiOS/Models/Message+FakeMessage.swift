//
//  Message+FakeMessage.swift
//  pEp
//
//  Created by Andreas Buff on 10.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
/// Code related to fake messages.
/// 
/// We are saving fake messages locally for messages that take time to sync with server (e.g.
/// when moving a message to another folder). Fake messages are marked with a special UID.
extension Message {

    func saveFakeMessage(for msg: Message, in targetFolder: Folder) {
        let fakeMsg = Message(uid: Message.uidFakeResponsivenes,
                              message: msg,
                              parentFolder: targetFolder)
        if let origFlags = msg.imapFlags {
            // Take over user editable flags
            fakeMsg.imapFlags?.flagged = origFlags.flagged
            fakeMsg.imapFlags?.seen = origFlags.seen
            fakeMsg.imapFlags?.answered = origFlags.answered
        }
        fakeMsg.targetFolder = nil
        fakeMsg.save()
    }

    convenience init(uid: Int, message: Message, parentFolder: Folder) {
        self.init(uid: uid, message: message)
        self.parent = parentFolder
    }

    static func existingFakeMessage(for msg: CWIMAPMessage, in folder: Folder) -> Message? {
        // need search for uid -1 uuid parent
        if let uuid = msg.messageID() {
            return Message.by(uid: Message.uidFakeResponsivenes,
                              uuid: uuid,
                              folderName: folder.name,
                              accountAddress: folder.account.user.address)
        }
        return nil
    }

    /// We are saving fake messages locally for messages that take time to sync with server (e.g.
    /// when moving a message to another folder). Fake messages are marked with a special UID.
    ///
    ///This method is looking for a fake message with the UUID of the given message (received from
    /// server) and makes it a real message. This way we are trying to avoid replacing the fake
    /// message and thus to avoid inconsitencies (uses has altered fake message, chages gone)
    ///
    /// - Parameters:
    ///   - msg: real message to update fake message with
    ///   - folder: parent folder
    /// - Returns:  true if a fake message with the give UUID has been found and updated,
    ///             false otherwize
    static public func replaceFakeMessage(withRealMessage msg: CWIMAPMessage, in folder: Folder) -> Bool {
        if let existingFakeMessage = Message.existingFakeMessage(for: msg,
                                                                 in: folder) {
            existingFakeMessage.updateUid(newValue: Int(msg.uid()))
            let isRealMessageNow = existingFakeMessage
            isRealMessageNow.save()
            MessageModelConfig.messageFolderDelegate?.didUpdate(messageFolder: isRealMessageNow)
            return true
        } else {
            return false
        }
    }
}
