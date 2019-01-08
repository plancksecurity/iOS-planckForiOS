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

    public var isFakeMessage: Bool {
        return uid == Message.uidFakeResponsivenes
    }

    static public func saveForAppend(msg: Message) {
        let folder = msg.parent
        let uuid = MessageID.generateUUID()
        let appendMsg = Message(uid: uidNeedsAppend, message: msg, parentFolder: folder)
        appendMsg.uuid = uuid
        CdMessage.create(withContentOf: appendMsg)

        let fakeMsg = Message(uid: uidFakeResponsivenes, message: msg, parentFolder: folder)
        fakeMsg.uuid = uuid
        CdMessage.create(withContentOf: fakeMsg)
        Record.saveAndWait()
        MessageModelConfig.messageFolderDelegate?.didCreate(messageFolder: fakeMsg)
    }

    static public func createCdFakeMessage(for msg: Message) {
        let fakeMsg = Message(uid: Message.uidFakeResponsivenes,
                              message: msg,
                              parentFolder: msg.parent)
        fakeMsg.uuid = msg.uuid
        CdMessage.create(withContentOf: fakeMsg)
        Record.saveAndWait()
        MessageModelConfig.messageFolderDelegate?.didCreate(messageFolder: fakeMsg)
    }

    func saveFakeMessage(in targetFolder: Folder) {
        let fakeMsg = Message(uid: Message.uidFakeResponsivenes,
                              message: self,
                              parentFolder: targetFolder)
        if let origFlags = self.imapFlags {
            // Take over user editable flags
            fakeMsg.imapFlags?.flagged = origFlags.flagged
            fakeMsg.imapFlags?.seen = origFlags.seen
            fakeMsg.imapFlags?.answered = origFlags.answered
        }
        fakeMsg.targetFolder = nil
        fakeMsg.save()
    }

    private convenience init(uid: Int, message: Message, parentFolder: Folder) {
        self.init(uid: uid, message: message)
        self.parent = parentFolder
    }

    /// This method is looking for a fake message with/in the given UUID and folder delets it and
    /// returns its imap-flags.
    ///
    /// The falgs are of interest as the user might have chenged them while
    /// we were fetching the original (e.g. read a mail with altered the "seen" flag).
    ///
    /// - Parameters:
    ///   - uuid: uuid to identify the fake message with
    ///   - folder: folder to search in
    /// - Returns: imap flags of fake message if found, nil otherwize
    static public func findAndDeleteFakeMessage(
        withUuid uuid: String, in folder: Folder) -> ImapFlags? {
        var flags: ImapFlags? = nil
        if let existingFakeMessage = Message.existingFakeMessage(for: uuid, in: folder) {
            flags = existingFakeMessage.imapFlags
            existingFakeMessage.delete()
        }
        return flags
    }

    static private func existingFakeMessage(for uuid: String, in folder: Folder) -> Message? {
        guard
            let fakeMsg =  Message.by(uid: Message.uidFakeResponsivenes,
                                      uuid: uuid,
                                      folderName: folder.name,
                                      accountAddress: folder.account.user.address),
            fakeMsg.uid == Message.uidFakeResponsivenes
            else {
                // pEp workaround factory:
                // This works around the fact that this happens but shoud not.
                return nil
        }
        return fakeMsg
    }
}
