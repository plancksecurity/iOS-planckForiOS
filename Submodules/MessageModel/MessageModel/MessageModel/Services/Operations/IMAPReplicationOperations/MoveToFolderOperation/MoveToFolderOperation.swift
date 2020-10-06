//
//  MoveToFolderOperation.swift
//  pEp
//
//  Created by Andreas Buff on 10.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework
import pEpIOSToolbox

/// Moves all messages in the given folder to targetFolder if parent != tagetfolder.
class MoveToFolderOperation: ImapSyncOperation {
    /// Folder to move messages from
    private let folderInfo: FolderInfoCache
    private var lastProcessedMessage: CdMessage?

    init(parentName: String = #function,
         imapConnection: ImapConnectionProtocol,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         folder: CdFolder) {
        self.folderInfo = FolderInfoCache(cdFolder: folder)

        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override public func main() {
        if !checkImapConnection() {
            waitForBackgroundTasksAndFinish()
            return
        }

        syncDelegate = MoveToFolderSyncDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        process()
    }
}

// MARK: - Private

extension MoveToFolderOperation {

    private func process() {
        if !imapConnection.openMailBox(name: folderInfo.name, updateExistsCount: false) {
            handleNextMessage()
        }
    }

    private func retrieveNextMessage() -> CdMessage? {
        guard let cdFolder = privateMOC.object(with: folderInfo.objectID) as? CdFolder else {
            return nil
        }
        return cdFolder.firstMessageThatHasToBeMoved(context: privateMOC)
    }

    /// When UID MOVEing a message, the server expunges the message and let us know. So Pantomime
    /// takes care to remove the expunged message. In case we are calling UID MOVE for a message
    /// that does not exist any more (maybe it has been moved by another client already in between),
    /// the server does not respond with an error but with OK. We have to make sure the message is
    /// removed from our store to avoid endless UID MOVE.
    private func deleteLastMovedMessage() {
        guard let toDelete = lastProcessedMessage else {
            return
        }
        privateMOC.delete(toDelete)
        lastProcessedMessage = nil
    }

    private func deleteLastCopiedMessage() {
        guard let toDelete = lastProcessedMessage else {
            return
        }
        toDelete.imapMarkDeleted()
        toDelete.targetFolder = toDelete.parent
        privateMOC.saveAndLogErrors()

        lastProcessedMessage = nil
    }

    private func handleNextMessage() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                guard !me.isCancelled, let message = me.retrieveNextMessage() else {
                    me.privateMOC.saveAndLogErrors()
                    me.waitForBackgroundTasksAndFinish()
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
                    Log.shared.errorAndCrash("I wounder why we are here then.")
                    me.handleNextMessage()
                    return
                }
                guard let targetFolderName = message.targetFolder?.name else {
                    me.handleIlligalStateErrorAndFinish(hint: "No target folder")
                    return
                }
                me.lastProcessedMessage = message

                guard message.uid > 0 else {
                    me.handleIlligalStateErrorAndFinish(hint: "Invalid UID")
                    return
                }
                let uid = UInt(message.uid)

                me.imapConnection.moveMessage(uid: uid, toFolderWithName: targetFolderName)
                me.assureMovedMessageWillBeFetched(forMessageToMove: message)
            }
        }
    }

    private func assureMovedMessageWillBeFetched(forMessageToMove cdMessage: CdMessage) {
        cdMessage.targetFolder?.lastLookedAt = Date()
    }
}

// MARK: - Callback Handler

extension MoveToFolderOperation {

    fileprivate func handleFolderOpenCompleted() {
        handleNextMessage()
    }

    fileprivate func handleMessageUidMoveCompleted() {
        handleNextMessage()
    }

    /// UID MOVE is part of an IMAP extension. Not all servers support it.
    /// In case UID MOVE fails, we mimik its behaviour:
    /// - UID COPY the message to the target folder (is supposed to be supported by all servers)
    /// - mark the original message as /deleted
    fileprivate func handleUidMoveIsUnsupported() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                guard let toCopy = me.lastProcessedMessage,
                    let targetFolder = toCopy.targetFolder else {
                        me.handleIlligalStateErrorAndFinish(hint:
                            "Why are we even called if there is nothing to do?")
                        return
                }
                let uidCopyOp = UIDCopyOperation(imapConnection: me.imapConnection,
                                                 context: me.privateMOC,
                                                 errorContainer: me.errorContainer,
                                                 message: toCopy,
                                                 targetFolder: targetFolder)
                me.backgroundQueue.addOperation(uidCopyOp)
            }
        }
    }

    fileprivate func handleMessageCopyCompleted() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                if let error = me.errorContainer.error {
                    me.handle(error: error)
                    return
                }
                me.deleteLastCopiedMessage()
                me.handleNextMessage()
            }
        }
    }
}

// MARK: - MoveToFolderSyncDelegate

class MoveToFolderSyncDelegate: DefaultImapConnectionDelegate {

    // MARK: Success

    override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash("No handler")
            return
        }
        op.handleFolderOpenCompleted()
    }

    override func messageUidMoveCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash("No handler")
            return
        }
        op.handleMessageUidMoveCompleted()
    }

    override func messagesCopyCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash("No handler")
            return
        }
        handler.handleMessageCopyCompleted()
    }

    // MARK: Error

    override func folderOpenFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        handle(error: ImapSyncOperationError.actionFailed, on: errorHandler)
    }

    public override func badResponse(_ imapConnection: ImapConnectionProtocol, response: String?) {
        handle(error: ImapSyncOperationError.badResponse(response) , on: errorHandler)
    }

    public override func actionFailed(_ imapConnection: ImapConnectionProtocol, response: String?) {
        handle(error: ImapSyncOperationError.actionFailed, on: errorHandler)
    }

    override func messageUidMoveFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash("No handler")
            return
        }
        // UID MOVE failed. We assume the server does not support it and use UID COPY as
        // backup plan.
        handler.handleUidMoveIsUnsupported()
    }

    override func messagesCopyFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        handle(error: ImapSyncOperationError.actionFailed, on: errorHandler)
    }

    // MARK: Helper

    private func handle(error: Error, on errorHandler: ImapConnectionDelegateErrorHandlerProtocol?) {
        guard let handler = errorHandler as? MoveToFolderOperation else {
            Log.shared.errorAndCrash("Wrong delegate called")
            return
        }
        handler.handle(error: error)
    }
}
