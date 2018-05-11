//
//  UIDCopyOperation.swift
//  pEp
//
//  Created by Andreas Buff on 11.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class UIDCopyOperation: ImapSyncOperation {
    var syncDelegate: UIDCopyOperationSyncDelegate?
    let originalMessage: Message
    let targetFolder: Folder

    init(parentName: String = #function,
         imapSyncData: ImapSyncData,
         errorContainer: ServiceErrorProtocol = ErrorContainer(),
         message: Message,
         targetFolder: Folder) {
        self.originalMessage = message
        self.targetFolder = targetFolder
        super.init(parentName: parentName,
                   errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override public func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }
        syncDelegate = UIDCopyOperationSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate
        process()
    }
//
//    override func markAsFinished() {
//        syncDelegate = nil
//        super.markAsFinished()
//    }
//
//    private func retrieveNextMessage() -> Message? {
//        var result: Message? = nil
//        MessageModel.performAndWait { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
//                return
//            }
//            guard let msg = me.folder.firstMessageThatHasToBeMoved() else {
//                return
//            }
//            result = msg
//        }
//        return result
//    }
//

    private func process() {
        if let sync = imapSyncData.sync {
            if !sync.openMailBox(name: originalMessage.parent.name) {
                handleMessage()
            }
        } else {
            handle(error: BackgroundError.GeneralError.illegalState(info: "No sync"))
        }
    }

    fileprivate func handleMessage() {
        MessageModel.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
                return
            }
            let imapFolder = CWIMAPFolder(name: me.originalMessage.parent.name)
            if let sync = me.imapSyncData.sync {
                imapFolder.setStore(sync.imapStore)
            }
            imapFolder.copyMessage(withUid: me.originalMessage.uid,
                                   toFolderNamed: me.targetFolder.name)
        }
    }
}



// MARK: - UIDCopyOperationSyncDelegate

class UIDCopyOperationSyncDelegate: DefaultImapSyncDelegate {
    // MARK: Success

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? UIDCopyOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.handleMessage()
    }

    override func messagesCopyCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let handler = errorHandler as? UIDCopyOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "No handler")
            return
        }
        handler.markAsFinished()
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
        guard let handler = errorHandler as? UIDCopyOperation else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong delegate called")
            return
        }
        handler.addIMAPError(error)
        handler.markAsFinished()
    }
}
