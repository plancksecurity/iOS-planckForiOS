//
//  Message+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    static let uidNeedsAppend = 0
    static let uidFakeResponsivenes = -1

    // MARK: - Deletion

    /// Use this method if you do not want the message to be moved to trash folder.
    /// Takes into account if parent folder is remote or local.
    func imapMarkDeleted() {
        if parent.folderType.isSyncedWithServer {
            internalImapMarkDeleted()
        } else {
            delete()
        }
    }

    /// Triggers trashing of the message, taking everithing in account (parent is local or remote,
    /// provider specific constrains ...).
    /// Always use this method to handle "user has choosen to delete an e-mail".
    func imapDelete() {
        if parent.folderType.isSyncedWithServer {
            internalImapDelete()
        } else {
            delete()
        }
    }

    /// Sets flag "deleted".
    /// Use this method if you do not want the message to be moved to trash folder.
    /// Note: Use only for messages synced with an IMAP server.
    private func internalImapMarkDeleted() {
        guard self.parent.folderType.isSyncedWithServer else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString:
                "This method must not be called for messages in local folders.")
            return
        }
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        self.save()
    }

    /// Triggers trashing of the message, taking everithing in account (provider specific constrains
    /// and such).
    /// Always use this method to handle "user has choosen to delete an e-mail".
    /// Note: Use only for messages synced with an IMAP server.
    private func internalImapDelete() {
        guard self.parent.folderType.isSyncedWithServer else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString:
                "This method must not be called for messages in local folders.")
            return
        }
        guard let trashFolder = parent.account.folder(ofType: .trash) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have a trash folder at this point")
            return
        }

        if parent.shouldUidMoveDeletedMessagesToTrash {
            move(to: trashFolder)
        } else {
            imapMarkDeleted()
        }
    }

    // MARK: - Move to Folder

    /// Marks the message for moving to the given folder.
    ///
    /// Does not actually move the message but set it's target folder.
    /// The Backgound layer has to take care of the actual move.
    /// 
    /// Returns immediately in case the message is in the target folder already.
    ///
    /// - Parameter targetFolder: folder to move the message to
    func move(to targetFolder:Folder) {
        guard parent != targetFolder else {
            // the message is in the target folder already. No need to move it.
            return
        }
        if targetFolder.account == parent.account {
            //IOS-647
            saveFakeMessage(for: self, in: targetFolder)

            self.targetFolder = targetFolder
            save()
        } else {
            //IOS-647
            // Copying to another account impossible due to UID 0 and UID fake have the same UUID. Would need way more complex algo.

            // The message must be moved to another account. Thus ...
            // ... we save a copy for append in target accounts folder ...
            let copy = Message(message: self)
            copy.parent = targetFolder
            copy.save()
            // ... and delete the original.
            self.imapMarkDeleted()
        }
    }

    //IOS-647

    private func saveFakeMessage(for msg: Message, in targetFolder: Folder) {
        let fakeMsg = Message(uid: Message.uidFakeResponsivenes,
                              message: msg,
                              parentFolder: targetFolder)
        fakeMsg.targetFolder = nil
        fakeMsg.save()
    }

    convenience init(uid: Int, message: Message, parentFolder: Folder) {
        self.init(uid: uid, message: message)
        self.parent = parentFolder
    }

    //IOS-647 extend CWIMAPMessage for that?
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
