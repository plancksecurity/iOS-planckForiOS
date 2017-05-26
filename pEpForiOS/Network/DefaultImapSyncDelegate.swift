//
//  DefaultImapSyncDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

/**
 Default implementation of `ImapSyncDelegate` for `ImapSyncOperation`s
 that considers everything to be an error ('illegal state').
 */
class DefaultImapSyncDelegate: ImapSyncDelegate {
    weak var imapSyncOperation: ImapSyncOperation?

    public init(imapSyncOperation: ImapSyncOperation) {
        self.imapSyncOperation = imapSyncOperation
    }

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }

    public func badResponse(_ sync: ImapSync, response: String?) {
        imapSyncOperation?.addIMAPError(ImapSyncError.illegalState(#function))
        imapSyncOperation?.markAsFinished()
    }
}
