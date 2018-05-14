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
            toDelete.targetFolder = toDelete.parent
            toDelete.imapFlags?.deleted = true
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
        deleteLastMovedMessage()
        MessageModel.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
                return
            }
            guard let message = me.retrieveNextMessage() else {
                me.markAsFinished()
                return
            }
            if message.parent == message.targetFolder { //IOS-663 merge in guard?
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "I wounder why we are here then.")
                me.handleNextMessage()
                return
            }
            guard let targetFolderName = message.targetFolder?.name else {
                Log.shared.errorAndCrash(component: #function, errorString: "No target folder")
                me.markAsFinished()
                return
            }
            me.lastProcessedMessage = message
            let imapFolder = CWIMAPFolder(name: me.folder.name)
            if let sync = me.imapSyncData.sync {
                imapFolder.setStore(sync.imapStore)
            }
            imapFolder.moveMessage(withUid: message.uid, toFolderNamed: targetFolderName)
        }
    }

    /// UID MOVE is part of an IMAP extension. Not all servers support it.
    /// In case UID MOVE fails, we mimik its behaviour:
    /// - UID COPY the message to the target folder (is supposed to be supported by all servers)
    /// - mark the original message as /deleted
    fileprivate func handleUidMoveIsUnsupported() {
        guard let toCopy = lastProcessedMessage,
            let targetFolder = toCopy.targetFolder else {
                return
        }
        let uidCopyOp = UIDCopyOperation(imapSyncData: imapSyncData,
                                         errorContainer: errorContainer,
                                         message: toCopy,
                                         targetFolder: targetFolder)
        uidCopyOp.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            if let error = me.errorContainer.error {
                me.addIMAPError(error)
                me.markAsFinished()
                return
            }
            me.deleteLastCopiedMessage()
        }
        backgroundQueue.addOperation(uidCopyOp)
    }

    static func foldersContainingMarkedForMoveToFolder() -> [Folder] {
        var result = [Folder]()
        MessageModel.performAndWait {
            let allUidMoveMessages = Message.allMessagesMarkedForMoveToFolder()
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

    // MARK: Error

    override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        handle(error: ImapSyncError.actionFailed, on: errorHandler)
    }

    public override func badResponse(_ sync: ImapSync, response: String?) {
        handle(error: ImapSyncError.badResponse(response) , on: errorHandler)
    }

    public override func actionFailed(_ sync: ImapSync, response: String?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        /// UID MOVE failed. We assume the server does not support it.
        handler.handleUidMoveIsUnsupported()
    }

    //    override func message //IOS-663: Message Expunge needs handling?

    // MARK: Helper

    private func handle(error: Error, on errorHandler: ImapSyncDelegateErrorHandlerProtocol?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong delegate called")
            return
        }
        handler.addIMAPError(error)
        handler.markAsFinished()
    }
}

