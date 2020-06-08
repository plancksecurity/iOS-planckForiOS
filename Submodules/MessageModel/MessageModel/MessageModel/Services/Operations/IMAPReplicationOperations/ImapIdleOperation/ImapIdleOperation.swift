//
//  ImapIdleOperation.swift
//  pEpForiOS
//
//  Created by buff on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

/// Sets and keeps an account in IDLE mode 
/// if:
///     * IDLE is supported by server
/// while:
///     * No errors occur
///     * The server does not report any changes
///     * There are no local changes made by the user
///
/// In other words Idle mode is stopped in case an error occurs, changes on server site are reported or the user made changes.
class ImapIdleOperation: ImapSyncOperation {
    /// MOC to use with FRC
    private let frcMoc: NSManagedObjectContext = Stack.shared.changePropagatorContext
    /// Monitiors all messages of the 
    private var frc: NSFetchedResultsController<CdMessage> = NSFetchedResultsController() // Dummy FRC to be able to initialize in init(). Do NOT use this.

    //    var syncDelegate: ImapIdleDelegate?
    var changedMessageIDs = [NSManagedObjectID]()
    //    weak var delegate: ImapIdleOperationDelegate?

    override init(parentName: String = #function,
                  context: NSManagedObjectContext? = nil,
                  errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                  imapConnection: ImapConnectionProtocol) {
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)

        frcMoc.performAndWait {
            let fetchRequest = NSFetchRequest<CdMessage>()
            fetchRequest.sortDescriptors = []
            fetchRequest.entity = CdMessage.entity()
            if let cdAccount = imapConnection.cdAccount(moc: frcMoc) {
                fetchRequest.predicate = CdMessage.PredicateFactory.belongingToAccount(cdAccount: cdAccount)
            } else {
                Log.shared.errorAndCrash("No CdAccount")
            }

            frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: frcMoc,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
            frc.delegate = self
        }
    }

    func stopIdle() { //BUFF:
        sendDone()
    }

    override func main() {
        if !checkImapSync() {
            waitForBackgroundTasksAndFinish()
            return
        }
        if !imapConnection.supportsIdle {
            markAsFinished()
            return
        }
        frcMoc.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            do {
                try me.frc.performFetch()
            } catch {
                Log.shared.errorAndCrash("Error fetching: %@", error.localizedDescription)
            }
            me.process()
        }
    }

    private func process() {
        syncDelegate = ImapIdleDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        startIdle(context: self.privateMOC)
    }

    private func startIdle(context: NSManagedObjectContext) {
        imapConnection.sendIdle()
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    private func sendDone() {
        Log.shared.info("Stopping IDLE mode")
       imapConnection.exitIdle()
    }

    fileprivate func handleIdleNewMessages() {
        sendDone()
    }

    fileprivate func handleIdleFinished() {
        markAsFinished()
    }

    fileprivate func handleError() {
        Log.shared.info("We intentionally ignore an error here.")
    }

    fileprivate func handleLocalChangeHappened() {
        // The user changes a message (delted, flagged, moved, ...).
        // Exit idle mode to sync those changes to the IMAP server.
        Log.shared.info("%@: Local change reported", type(of: self).description())
        sendDone()
    }
}

// MARK: - ImapIdleDelegate

//BUFF: cleanup
class ImapIdleDelegate: DefaultImapConnectionDelegate {
    
    override func authenticationFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncOperationError.illegalState(#function))
        imapIdleOp()?.handleError()
    }

//    public override func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
//        errorHandler?.handle(error: ImapSyncError.illegalState(#function))
//        imapIdleOp()?.handleError()
//    }

    override func connectionLost(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

//    public override func connectionLost(_ sync: ImapSync, notification: Notification?) {
//        imapIdleOp()?.handleError()
//    }

    override func connectionTerminated(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

//    public override func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
//        imapIdleOp()?.handleError()
//    }

    override func connectionTimedOut(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

//    public override func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
//        imapIdleOp()?.handleError()
//    }

    override func badResponse(_ imapConection: ImapConnectionProtocol, response: String?) {
        imapIdleOp()?.handleError()
    }

//    public override func badResponse(_ sync: ImapSync, response: String?) {
//        imapIdleOp()?.handleError()
//    }

    override func actionFailed(_ imapConection: ImapConnectionProtocol, response: String?) {
        imapIdleOp()?.handleError() //BUFF: double check all error handling. We do not want to inform the user if idle fails but keep on replicating
    }

//    public override func actionFailed(_ sync: ImapSync, response: String?) {
//        imapIdleOp()?.handleError()
//    }

    override func idleEntered(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        Log.shared.info("IDLE mode entered")
        // Do nothing, keep idleing
    }

//    override func idleEntered(_ sync: ImapSync, notification: Notification?) {
//        // Do nothing, keep idleing
//    }

    override func idleNewMessages(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleIdleNewMessages()
    }
    
//    override func idleNewMessages(_ sync: ImapSync, notification: Notification?) {
//        imapIdleOp()?.handleIdleNewMessages()
//    }

    override func idleFinished(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        Log.shared.info("IDLE mode finished")
        imapIdleOp()?.handleIdleFinished()
    }
    
//    override func idleFinished(_ sync: ImapSync, notification: Notification?) {
//        imapIdleOp()?.handleIdleFinished()
//    }

    /// We did stop ideling by sending DONE, so the server returns the actual changes.
    /// We are currently ignoring those reports and signal to our client that ideling finished.
    override func messageChanged(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleIdleFinished() //BUFF: read RFC. What do we get here?
    }

//    /// We did stop ideling by sending DONE, so the server returns the actual changes.
//    /// We are currently ignoring those reports and signal to our client that ideling finished.
//    override func messageChanged(_ sync: ImapSync, notification: Notification?) {
//        imapIdleOp()?.handleIdleFinished()
//    }

    // MARK: - Helper 

    private func imapIdleOp() -> ImapIdleOperation? {
        guard let imapIdleOp = errorHandler as? ImapIdleOperation else {
            return nil
        }
        return imapIdleOp
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension ImapIdleOperation: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We are using a trivial implementation until we need somthing more sofisticated.
        // Any change on any CdMessage will stop idle mode.
        handleLocalChangeHappened()
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // do nothing
    }
}
