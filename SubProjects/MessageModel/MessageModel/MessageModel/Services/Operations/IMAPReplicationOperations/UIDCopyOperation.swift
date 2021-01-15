//
//  UIDCopyOperation.swift
//  pEp
//
//  Created by Andreas Buff on 11.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework
import CoreData
import pEpIOSToolbox

class UIDCopyOperation: ImapSyncOperation {
    private let originalMessageInfo: MessageInfoCache
    private let targetFolder: FolderInfoCache

    init(parentName: String = #function,
         imapConnection: ImapConnectionProtocol,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         message: CdMessage,
         targetFolder: CdFolder) {
        self.originalMessageInfo = MessageInfoCache(cdMessage: message)
        self.targetFolder = FolderInfoCache(cdFolder: targetFolder)
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override public func main() {
        if !checkImapSync() {
            waitForBackgroundTasksAndFinish()
            return
        }
        syncDelegate = UIDCopyOperationSyncDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        process()
    }
}

// MARK: - Private

extension UIDCopyOperation {

    private func process() {
        if !imapConnection.openMailBox(name: originalMessageInfo.folderName, updateExistsCount: false) {
            handleMessage()
        }
    }

    private func handleMessage() {
        guard originalMessageInfo.uid > 0 else {
            handle(error: BackgroundError.GeneralError.illegalState(info:
                "Invalid UID for this action"))
            return
        }
        let uid = UInt(originalMessageInfo.uid)
        imapConnection.copyMessage(uid: uid, toFolderWithName: originalMessageInfo.folderName)
    }
}

// MARK: - Callback Handler

extension UIDCopyOperation {

    fileprivate func handlerMessagesCopyCompleted() {
        waitForBackgroundTasksAndFinish()
    }

    fileprivate func handlerFolderOpenCompleted() {
        handleMessage()
    }
}

// MARK: - UIDCopyOperationSyncDelegate

class UIDCopyOperationSyncDelegate: DefaultImapConnectionDelegate {
    // MARK: Success

    override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let handler = errorHandler as? UIDCopyOperation else {
            Log.shared.errorAndCrash("No handler")
            return
        }
        handler.handlerFolderOpenCompleted()
    }

    override func messagesCopyCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let handler = errorHandler as? UIDCopyOperation else {
            Log.shared.errorAndCrash("No handler")
            return
        }
        handler.handlerMessagesCopyCompleted()
    }

    // MARK: Error

    override func folderOpenFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        handle(error: ImapSyncOperationError.actionFailed, on: errorHandler)
    }

    public override func badResponse(_ imapConnection: ImapConnectionProtocol, response: String?) {
        handle(error: ImapSyncOperationError.badResponse(response) , on: errorHandler)
    }

    override func messagesCopyFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        handle(error: ImapSyncOperationError.actionFailed, on: errorHandler)
    }
    
    public override func actionFailed(_ imapConnection: ImapConnectionProtocol, response: String?) {
        handle(error: ImapSyncOperationError.actionFailed, on: errorHandler)
    }

    // MARK: Helper

    private func handle(error: Error, on errorHandler: ImapConnectionDelegateErrorHandlerProtocol?) {
        guard let handler = errorHandler as? UIDCopyOperation else {
            Log.shared.errorAndCrash("Wrong delegate called")
            return
        }
        handler.handle(error: error)
    }
}
