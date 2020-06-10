//
//  DefaultImapSyncDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

import PantomimeFramework

public protocol ImapConnectionDelegateErrorHandlerProtocol: class {
    func handle(error: Error)
}

/// Default implementation of `ImapConnectionDelegate` for `ImapSyncOperation`s
/// that considers everything to be an error ('illegal state').
class DefaultImapConnectionDelegate: ImapConnectionDelegate {
    public weak var errorHandler: ImapConnectionDelegateErrorHandlerProtocol?

    class CrashingErrorHandler: ImapConnectionDelegateErrorHandlerProtocol {
        func handle(error: Error) {
            Log.shared.errorAndCrash(
                "Error occurred, but no error handler defined: %@",
                "\(error)")
        }
    }

    public init(errorHandler: ImapConnectionDelegateErrorHandlerProtocol) {
        self.errorHandler = errorHandler
    }

    func forceErrorDelegate() -> ImapConnectionDelegateErrorHandlerProtocol {
        return errorHandler ?? CrashingErrorHandler()
    }

    func authenticationCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func receivedFolderNames(_ imapConection: ImapConnectionProtocol, folderNames: [String]?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func authenticationFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.authenticationFailed(
            #function,
            imapConection.accountAddress))
    }

    func connectionLost(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        var setSpecializedError = false

        if let error = notification?.userInfo?[PantomimeErrorExtra] as? NSError {
            switch Int32(error.code) {
            case errSSLPeerCertUnknown:
                forceErrorDelegate().handle(error: ImapSyncOperationError.clientCertificateNotAccepted)
                setSpecializedError = true
            case errSSLClosedAbort:
                if imapConection.isClientCertificateSet {
                    forceErrorDelegate().handle(error: ImapSyncOperationError.clientCertificateNotAccepted)
                    setSpecializedError = true
                }
            default:
                break
            }
        }

        if !setSpecializedError {
            // Did not find a more specific explanation for the error, so use the generic one
            forceErrorDelegate().handle(error: ImapSyncOperationError.connectionLost(#function))
        }
    }

    func connectionTerminated(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.connectionTerminated(#function))
    }

    func connectionTimedOut(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.connectionTimedOut(#function))
    }

    func folderFetchCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderSyncCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderSyncFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messageChanged(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        // Some servers will send unsolicited flag changes in answer
        // to all kinds of (unrelated) requests. By default,we ignore them.
        // Override this method if you need to explicitly handle it in your operation.
    }

    func messagePrefetchCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderOpenCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderOpenFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderStatusCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderListCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderNameParsed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderAppendCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderAppendFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messageStoreCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messageStoreFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messageUidMoveCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messageUidMoveFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messagesCopyCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func messagesCopyFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderCreateCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderCreateFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderDeleteCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func folderDeleteFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func badResponse(_ imapConection: ImapConnectionProtocol, response: String?) {
        let msg = response ?? "?"
        forceErrorDelegate().handle(
            error: ImapSyncOperationError.illegalState("#function, response: \(msg)"))
    }

    func actionFailed(_ imapConection: ImapConnectionProtocol, response: String?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.actionFailed)
    }

    func idleEntered(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func idleNewMessages(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }

    func idleFinished(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        // I consider it OK to ignore this in all OPs but IDLE-OP. Comment in in case of problems.
//        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function)) //BUFF:
        Log.shared.info("DefaultImapConnectionDelegate: unhandled call to idleFinished")
    }

    func folderExpungeCompleted(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        forceErrorDelegate().handle(error: ImapSyncOperationError.illegalState(#function))
    }
}
