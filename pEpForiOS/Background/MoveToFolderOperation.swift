//
//  MoveToFolderOperation.swift
//  pEp
//
//  Created by Andreas Buff on 10.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/// Moves all messages in the given folder to targetFolder if parent != tagetfolder.
class MoveToFolderOperation: ImapSyncOperation {

    var syncDelegate: MoveToFolderSyncDelegate?
    /// Folder to move messages from
    let folder: Folder
    var lastProcessedMessage: Message?

    init(parentName: String = #function, imapSyncData: ImapSyncData,
         errorContainer: ServiceErrorProtocol = ErrorContainer(), folder: Folder) {
        self.folder = folder

        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override public func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }

        syncDelegate = MoveToFolderSyncDelegate(errorHandler: self)
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
            guard let msg = me.folder.firstMessageThatHasToBeMoved() else {
                return
            }
            result = msg
        }
        return result
    }

    /// When UID MOVEing a message, the server expunges the message and let us know. So Pantomime
    /// takes care to remove the expunged message. I case we are calling UID MOVE for a message that
    /// does not exist any more (maybe it has been moved by another client already in between), the
    /// server deos not repond with an error but with OK. We have to make sure the message is
    /// removed from our store to avoid endless UID MOVE.
    private func deleteLastMovedMessage() {
        guard let toDelete = lastProcessedMessage else {
            return
        }
        MessageModel.performAndWait {
            toDelete.delete()
        }
        lastProcessedMessage = nil
    }

    private func deleteLastCopiedMessage() {
        guard let toDelete = lastProcessedMessage else {
            return
        }
        MessageModel.performAndWait {
            toDelete.imapMarkDeleted()
            toDelete.targetFolder = toDelete.parent
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

    fileprivate func handleNextMessage() {
        guard !isCancelled, let message = retrieveNextMessage() else {
            waitForBackgroundTasksToFinish()
            return
        }
        MessageModel.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
                return
            }
            guard !me.isCancelled else {
                me.waitForBackgroundTasksToFinish()
                return
            }

            if message == me.lastProcessedMessage {
                // When UID MOVEing a message, the server expunges the message and let us know.
                // Pantomime takes care to remove the expunged message in general.
                // BUT:
                // In case we are calling UID MOVE for a message that does not exist any more (maybe
                // it has been moved by another client already in between), the server does not
                // respond with an error but with OK, so the local message still exists.
                // Thus we have to make sure the message is removed from our store to avoid endless
                // UID MOVE -> completed -> nextMessage -> UID MOVE ...
                me.deleteLastMovedMessage()
                me.handleNextMessage()
                return
            }
            if message.parent == message.targetFolder {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "I wounder why we are here then.")
                me.handleNextMessage()
                return
            }
            guard let targetFolderName = message.targetFolder?.name else {
                me.handleIlligalStateErrorAndFinish(hint: "No target folder")
                return
            }
            me.lastProcessedMessage = message
            let imapFolder = CWIMAPFolder(name: me.folder.name)
            if let sync = me.imapSyncData.sync {
                imapFolder.setStore(sync.imapStore)
            }
            guard message.uid > 0 else {
                me.handleIlligalStateErrorAndFinish(hint: "Invalid UID")
                return
            }
            let uid = UInt(message.uid)
            imapFolder.moveMessage(withUid: uid, toFolderNamed: targetFolderName)
        }
    }

    /// UID MOVE is part of an IMAP extension. Not all servers support it.
    /// In case UID MOVE fails, we mimik its behaviour:
    /// - UID COPY the message to the target folder (is supposed to be supported by all servers)
    /// - mark the original message as /deleted
    fileprivate func handleUidMoveIsUnsupported() {
        guard let toCopy = lastProcessedMessage,
            let targetFolder = toCopy.targetFolder else {
                handleIlligalStateErrorAndFinish(hint:
                    "Why are we even called if there is nothing to do?")
                return
        }
        let uidCopyOp = UIDCopyOperation(imapSyncData: imapSyncData,
                                         errorContainer: errorContainer,
                                         message: toCopy,
                                         targetFolder: targetFolder)
        backgroundQueue.addOperation(uidCopyOp)
    }

    fileprivate func handleMessageCopyCompleted() {
        if let error = errorContainer.error {
            handleError(error)
            return
        }
        deleteLastCopiedMessage()
        handleNextMessage()
    }

    static func foldersContainingMarkedForMoveToFolder(connectInfo: EmailConnectInfo) -> [Folder] {
        var result = [Folder]()
        MessageModel.performAndWait {
            guard
                let accountId = connectInfo.accountObjectID,
                let cdAccount = Record.Context.background.object(with: accountId) as? CdAccount else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No account.")
                    return
            }
            let account = cdAccount.account()
            let allUidMoveMessages = Message.allMessagesMarkedForMoveToFolder(inAccount: account)
            let foldersContainingMarkedMessages = allUidMoveMessages.map { $0.parent }
            result = Array(Set(foldersContainingMarkedMessages))
        }
        return result
    }
}

// MARK: - MoveToFolderSyncDelegate

class MoveToFolderSyncDelegate: DefaultImapSyncDelegate {
    // MARK: Success

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleNextMessage()
    }

    override func messageUidMoveCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleNextMessage()
    }

    override func messagesCopyCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleMessageCopyCompleted()
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

    override func messageUidMoveFailed(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        // UID MOVE failed. We assume the server does not support it and use UID COPY as
        // backup plan.
        handler.handleUidMoveIsUnsupported()
    }

    override func messagesCopyFailed(_ sync: ImapSync, notification: Notification?) {
        handle(error: ImapSyncError.actionFailed, on: errorHandler)
    }

    // MARK: Helper

    private func handle(error: Error, on errorHandler: ImapSyncDelegateErrorHandlerProtocol?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong delegate called")
            return
        }
        handler.handleError(error)
    }
}

