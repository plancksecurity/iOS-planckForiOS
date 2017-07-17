//
//  DefaultImapSyncDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

protocol ImapSyncDelegateErrorHandlerProtocol: class {
    func handle(error: Error)
}

/**
 Default implementation of `ImapSyncDelegate` for `ImapSyncOperation`s
 that considers everything to be an error ('illegal state').
 */
class DefaultImapSyncDelegate: ImapSyncDelegate {
    weak var errorHandler: ImapSyncDelegateErrorHandlerProtocol?

    public init(errorHandler: ImapSyncDelegateErrorHandlerProtocol) {
        self.errorHandler = errorHandler
    }

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.connectionLost(#function))
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.connectionTerminated(#function))
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.connectionTimedOut(#function))
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func badResponse(_ sync: ImapSync, response: String?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }

    public func actionFailed(_ sync: ImapSync, response: String?) {
        errorHandler?.handle(error: ImapSyncError.actionFailed)
    }

    func idleNewMessages(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    }
}
