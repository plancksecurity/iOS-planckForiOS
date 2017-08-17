//
//  ImapIdleOperation.swift
//  pEpForiOS
//
//  Created by buff on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

/// Sets and keeps an account in IDLE mode 
/// if:
///     - IDLE is supported by server
/// while:
///     - No errors occure
///     - The server does not report any changes
///
/// In case an error occurs or changes on server site are reported, we simple finish the operation to signal 
/// this to the client.
class ImapIdleOperation: ImapSyncOperation {

    var syncDelegate: ImapIdleDelegate?
    var changedMessageIDs = [NSManagedObjectID]()
    //    weak var delegate: ImapIdleOperationDelegate?

    override func cancel() {
        super.cancel()
        markAsFinished()
    }

    override func main() {
        if !shouldRun() {
            return
        }
        if !checkImapSync() {
            return
        }
        if !imapSyncData.supportsIdle {
            markAsFinished()
            return
        }
        privateMOC.perform() {
            self.process()
        }
    }

    private func process() {
        syncDelegate = ImapIdleDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        startIdle(context: self.privateMOC)
    }

    private func startIdle(context: NSManagedObjectContext) {
        requestIdle()
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    private func requestIdle() {
        guard let imapStore = imapSyncData.sync?.imapStore else {
            Log.shared.errorAndCrash(component: #function, errorString: "No store!?")
            return
        }
        imapStore.send(IMAP_IDLE, info: nil, string: "IDLE")
    }

    private func sendDone() {
        guard let imapStore = imapSyncData.sync?.imapStore else {
            Log.shared.errorAndCrash(component: #function, errorString: "No store!?")
            return
        }
        imapStore.exitIDLE()
    }

    fileprivate func handleIdleNewMessages() {
        sendDone()
    }

    fileprivate func handleIdleFinished() {
        markAsFinished()
    }

    fileprivate func handleError() {
        Log.shared.info(component: #function, content: "We intentionally ignore an error here.")
        markAsFinished()
    }
}

// MARK: - ImapIdleDelegate (actual delegate)

class ImapIdleDelegate: DefaultImapSyncDelegate {
    public override func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
        imapIdleOp()?.handleError()
    }

    public override func connectionLost(_ sync: ImapSync, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

    public override func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

    public override func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

    public override func badResponse(_ sync: ImapSync, response: String?) {
        imapIdleOp()?.handleError()
    }

    public override func actionFailed(_ sync: ImapSync, response: String?) {
        imapIdleOp()?.handleError()
    }

    override func idleEntered(_ sync: ImapSync, notification: Notification?) {
        // Do nothing, keep idleing
    }
    
    override func idleNewMessages(_ sync: ImapSync, notification: Notification?) {
        imapIdleOp()?.handleIdleNewMessages()
    }
    
    override func idleFinished(_ sync: ImapSync, notification: Notification?) {
        imapIdleOp()?.handleIdleFinished()
    }

    /// We did stop ideling by sending DONE, so the server returns the actual changes.
    /// We are currently ignoring those reports and signal to our client that ideling finished.
    override func messageChanged(_ sync: ImapSync, notification: Notification?) {
        imapIdleOp()?.handleIdleFinished()
    }

    // MARK: - Helper 

    private func imapIdleOp() -> ImapIdleOperation? {
        guard let imapIdleOp = errorHandler as? ImapIdleOperation else {
            return nil
        }
        return imapIdleOp
    }
}
