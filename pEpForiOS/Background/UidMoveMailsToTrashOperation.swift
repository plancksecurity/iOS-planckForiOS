//
//  UidMoveMailsToTrashOperation.swift
//  pEp
//
//  Created by Andreas Buff on 10.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Soley implemented for Gmail.
/// Uses the UID MOVE command to move deleted mails to trash folder
/// (instead of copying and appending it).
/// That is the only way found to move a message from Gmails "All Messages" virtual mailbox
/// to "Trash".
class UidMoveMailsToTrashOperation: ImapSyncOperation {
    var syncDelegate: UidMoveMailsToTrashOperationSyncDelegate?
    /// Folder to move messages from
    let folder: Folder
    /// Folder type to move messages to
    let targetFolderType: FolderType
    /// Folder to move messages to
    var targetFolder: Folder?

    var lastProcessedMessage: Message?

    init(parentName: String = #function, imapSyncData: ImapSyncData,
         errorContainer: ServiceErrorProtocol = ErrorContainer(), folder: Folder) {
        self.folder = folder
        self.targetFolderType = .trash

        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
        determineTargetFolder()
    }

    override public func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }

        syncDelegate = UidMoveMailsToTrashOperationSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        process()
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    private func retrieveNextMessage() -> Message? {
        var result: Message? = nil
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
                return
            }
            guard let msg = me.folder.firstMessageMarkedForUidExpunge() else {
                return
            }
            result = msg
        }
        return result
    }

    private func deleteLastMovedMessage() {
        guard let toDelete = lastProcessedMessage else {
            return
        }

        MessageModel.performAndWait {
            toDelete.imapFields?.uidMoveToTrashStatus = .moved
            toDelete.delete()
            toDelete.save()
        }
        lastProcessedMessage = nil
    }

    private func process() {
        if let sync = imapSyncData.sync {
            if !sync.openMailBox(name: folder.name) {
                handleNextMessage()
            }
        } else {
            handle(error: BackgroundError.GeneralError.illegalState(info: "No sync"))
        }
    }

    private func handleNextMessage() {
        deleteLastMovedMessage()
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
                return
            }
            guard let message = me.retrieveNextMessage() else {
               me.markAsFinished()
                return
            }
            me.lastProcessedMessage = message

            guard let targetFolderName = me.targetFolder?.name else {
                Log.shared.errorAndCrash(component: #function, errorString: "No target folder")
                me.markAsFinished()
                return
            }
            let imapFolder = CWIMAPFolder(name: me.folder.name)
            if let sync = me.imapSyncData.sync {
                imapFolder.setStore(sync.imapStore)
            }
            imapFolder.moveMessage(withUid: message.uid, toFolderNamed: targetFolderName)
        }
    }

    private func determineTargetFolder() {
        guard let account = Account.by(address: folder.account.user.address) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No Account")
            markAsFinished()
            return
        }
        targetFolder = Folder.by(account: account, folderType: targetFolderType)
    }

    static func foldersContainingMarkedToUidMoveToTrash() -> [Folder] {
        var result = [Folder]()
        MessageModel.performAndWait {
            let allUidMoveMessages = Message.allMessagesMarkedForUidExpunge()
            let foldersContainingMarkedMessages = allUidMoveMessages.map { $0.parent }
            result = Array(Set(foldersContainingMarkedMessages))
        }
        return result
    }
}

// MARK: - UidPlusExpungeMailsSyncDelegate

class UidMoveMailsToTrashOperationSyncDelegate: DefaultImapSyncDelegate {

    // MARK: Success

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? UidMoveMailsToTrashOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleNextMessage()
    }

    override func messageUidMoveCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? UidMoveMailsToTrashOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleNextMessage()
    }

    // MARK: Error

    override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        handle(error: ImapSyncError.actionFailed, on: errorHandler)
    }

    public override func badResponse(_ sync: ImapSync, response: String?) {
        handle(error: ImapSyncError.badResponse(response) , on: errorHandler)
    }

    public override func actionFailed(_ sync: ImapSync, response: String?) {
        handle(error: ImapSyncError.actionFailed, on: errorHandler)
    }

    // MARK: Helper

    private func handle(error: Error, on errorHandler: ImapSyncDelegateErrorHandlerProtocol?) {
        guard let handler = errorHandler as? UidMoveMailsToTrashOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong delegate called")
            return
        }
        handler.addIMAPError(error)
        handler.markAsFinished()
    }
}
