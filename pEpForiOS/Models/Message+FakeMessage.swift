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

    /// Checks if a fake message for the given message exists and makes it a real message (by
    /// updating its UID) if so.
    ///
    /// - Parameters:
    ///   - folder: folder to search the fake message in
    ///   - msg: message fetched from server to search/update fake message for
    /// - Returns: true if a fake message with the give UUID has been found and updated,
    ///             false otherwize
    static
        public
        func fakeMessageExisted(in folder: Folder,
                                andHasBeenUpdatedWithUidOfRealMessage msg: CWIMAPMessage) -> Bool {
        guard let uuid = msg.messageID() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No UUID")
            return false
        }
        return checkExistanceOfFakeMessage(withUuid: uuid,
                                           in: folder,
                                           andUpdateItWithUidOfReceivedMessage: Int(msg.uid()))
    }

    /// We are saving fake messages locally for messages that take time to sync with server (e.g.
    /// when moving a message to another folder). Fake messages are marked with a special UID.
    ///
    /// This method is looking for a fake message with/in the given UUID and folder and updates its
    /// UID with the given, real UID that has been fetched from server. This way the fake message
    /// becomes a real one. We are trying to avoid replacing the fake message and thus to avoid
    /// inconsitencies (e.g. user marked fake message as SEEN, replacing the fake message would
    /// loose this information.)
    ///
    /// - Parameters:
    ///   - uuid: uuid to identify the fake message with
    ///   - folder: folder to search in
    ///   - realUid: UID of to update the fake message with
    /// - Returns: true if a fake message with the give UUID has been found and updated,
    ///            false otherwize
    static
        public
        func checkExistanceOfFakeMessage(withUuid uuid: String,
                                         in folder: Folder,
                                         andUpdateItWithUidOfReceivedMessage realUid: Int) -> Bool {
        if let existingFakeMessage = Message.existingFakeMessage(for: uuid, in: folder) {
            existingFakeMessage.updateUid(newValue: realUid)
            let isRealMessageNow = existingFakeMessage
            isRealMessageNow.save()
            MessageModelConfig.messageFolderDelegate?.didUpdate(messageFolder: isRealMessageNow)
            return true
        } else {
            return false
        }
    }

    static private func existingFakeMessage(for uuid: String, in folder: Folder) -> Message? {
        return Message.by(uid: Message.uidFakeResponsivenes,
                          uuid: uuid,
                          folderName: folder.name,
                          accountAddress: folder.account.user.address)
    }
}
