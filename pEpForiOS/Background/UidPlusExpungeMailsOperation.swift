//
//  UidPlusExpungeMailsOperation.swift
//  pEp
//
//  Created by Andreas Buff on 10.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class UidPlusExpungeMailsOperation: ImapSyncOperation {
    var syncDelegate: UidPlusExpungeMailsSyncDelegate?
    /// Folder to uidExpunge messages from
    let folder: Folder

    var lastProcessedMessage: Message?

    init(parentName: String = #function, imapSyncData: ImapSyncData,
         errorContainer: ServiceErrorProtocol = ErrorContainer(), folder: Folder) {
        self.folder = folder
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
        setupImapFolder()
    }

    override public func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        syncDelegate = UidPlusExpungeMailsSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        process()
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

    fileprivate func deleteLastExpungedMessage() {
        guard let toDelete = lastProcessedMessage else {
            return
        }
        MessageModel.performAndWait {
            toDelete.delete()
        }
        lastProcessedMessage = nil
    }

    private func setupImapFolder() {
        let imapFolder = CWIMAPFolder(name: folder.name)
        if let sync = imapSyncData.sync {
            imapFolder.setStore(sync.imapStore)
        }
    }

    fileprivate func process() {
        if let sync = imapSyncData.sync {
            if !sync.openMailBox(name: folder.name) {
                handleNextMessage()
            }
        }
    }

    fileprivate func handleNextMessage() {
        deleteLastExpungedMessage()
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
            do {
                try me.imapSyncData.sync?.expunge(uid: Int32(message.uid))
            } catch {
                Log.shared.errorAndCrash(component: #function, errorString: "Problem opening folder")
                me.lastProcessedMessage = nil
                me.addIMAPError(error)
                me.markAsFinished()
                return
            }
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    static func foldersContainingMarkedUidExpungeMessages() -> [Folder] {
        var result = [Folder]()
        MessageModel.performAndWait {
            let allUidExpunchMessages = Message.allMessagesMarkedForUidExpunge()
            let foldersContainingMarkedMessages = allUidExpunchMessages.map { $0.parent }
            result = Array(Set(foldersContainingMarkedMessages))
        }
        return result
    }
}

// MARK: - UidPlusExpungeMailsSyncDelegate

class UidPlusExpungeMailsSyncDelegate: DefaultImapSyncDelegate {
    // Success

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? UidPlusExpungeMailsOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleNextMessage()
    }

    override func messageUidExpungeCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? UidPlusExpungeMailsOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleNextMessage()
    }

    // Error

    override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        handle(error: ImapSyncError.actionFailed, on: errorHandler)
    }

    public override func badResponse(_ sync: ImapSync, response: String?) {
        handle(error: ImapSyncError.badResponse(response) , on: errorHandler)
    }

    public override func actionFailed(_ sync: ImapSync, response: String?) {
        handle(error: ImapSyncError.actionFailed, on: errorHandler)
    }

    // Helper
    private func handle(error: Error, on errorHandler: ImapSyncDelegateErrorHandlerProtocol?) {
        guard let handler = errorHandler as? UidPlusExpungeMailsOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong delegate called")
            return
        }
        handler.addIMAPError(error)
        handler.markAsFinished()
    }
}
