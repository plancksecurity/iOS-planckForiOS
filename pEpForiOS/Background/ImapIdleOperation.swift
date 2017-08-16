//
//  ImapIdleOperation.swift
//  pEpForiOS
//
//  Created by buff on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

//BUFF: Maybe inform about result (changes, stopped idle whatsoever.
//We currently do not want to use this information though afaics.
//protocol ImapIdleOperationDelegate: class {
//
//}

/// Sets and keeps an account in IDLE mode while:
/// - IDLE is supported by server
/// - No errors occure
/// - The server does not report any changes
//BUFF: change doc if we need a delegate
class ImapIdleOperation: ImapSyncOperation {

    var syncDelegate: ImapIdleDelegate?
    var changedMessageIDs = [NSManagedObjectID]()
    //    weak var delegate: ImapIdleOperationDelegate?

    override func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        if !imapSyncData.supportsIdle {
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

        //BUFF: select INBOX?

        guard let imapStore = imapSyncData.sync?.imapStore else {
            return
        }
        imapStore.send(IMAP_IDLE, info: nil, string: "IDLE")
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    fileprivate func handleIdleNewMessages() {
        markAsFinished()
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
    //BUFF: TODO: Handle callbacks
    //    public override init(errorHandler: ImapSyncDelegateErrorHandlerProtocol) {
    //        self.errorHandler = errorHandler
    //    }

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

    //    //BUFF: maybe
    //    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
    //        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    //    }
    //
    //
    //    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
    //        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
    //    }

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

    // MARK: - Helper 

    private func imapIdleOp() -> ImapIdleOperation? {
        guard let imapIdleOp = errorHandler as? ImapIdleOperation else {
            return nil
        }
        return imapIdleOp
    }
}
