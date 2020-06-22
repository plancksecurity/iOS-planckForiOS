//
//  ImapIdleOperation.swift
//  pEpForiOS
//
//  Created by buff on 16.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

extension ImapIdleOperation {
    /// The servers IDLE state
    private enum IdleState {
        // The OP did not communicate to the server yet
        case none
        // We asked the server to IDLE, but have no answer yet
        case requestedIdle
        // The servier is in IDLE mode
        case idling
        // The server is in IDLE mode, we send a request to stop IDLing but have no naswer yet
        case requestedDone
        // The server reported it successfully stopped IDLing
        case idleFinished
        // The server has reported an error
        case error

        var debugString: String {
            switch self {
            case .none:
                return "none"
            case .requestedIdle:
                return "requestedIdle"
            case .idling:
                return "idling"
            case .requestedDone:
                return "requestedDone"
            case .idleFinished:
                return "idleFinished"
            case .error:
                return "error"
            }
        }
    }

    /// Commands send from outside, where "outside" is the client or a FetchedResultsController reporting local changes.
    private enum Command {
        // The OP did not communicate to the server yet
        case none
        // Someone called cancel on the OP
        case cancel
        // We asked the server to IDLE, but have no answer yet
        case stopIdle

        var debugString: String {
            switch self {
            case .none:
                return ".none"
            case .cancel:
                return ".cancel"
            case .stopIdle:
                return ".stopIdle"
            }
        }
    }
}

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
    /// Monitiors all messages of the account
    private var frcForMessages: NSFetchedResultsController<CdMessage>?
    /// Monitiors all folders of the account.
    /// We need that to pull for "interesting folder" changes
    private var frcForFolders: NSFetchedResultsController<CdFolder>?

    private var state: IdleState = .none {
        didSet {
            Log.shared.info("IdleState has been set to %@", state.debugString)
        }
    }
    private var lastCommand: Command = .none {
        didSet {
            Log.shared.info("new command:%@", lastCommand == .none ? "none" : "stopIdle")
        }
    }

    private let serializeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService  = QualityOfService.background
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    override init(parentName: String = #function,
                  context: NSManagedObjectContext? = nil,
                  errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                  imapConnection: ImapConnectionProtocol) {
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)

        frcMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            // frcForMessages
            let fetchRequest = NSFetchRequest<CdMessage>()
            fetchRequest.sortDescriptors = []
            fetchRequest.entity = CdMessage.entity()
            if let cdAccount = imapConnection.cdAccount(moc: frcMoc) {
                fetchRequest.predicate = CdMessage.PredicateFactory.belongingToAccount(cdAccount: cdAccount)
            } else {
                Log.shared.errorAndCrash("No CdAccount")
            }
            me.frcForMessages = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                           managedObjectContext: me.frcMoc,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
            me.frcForMessages?.delegate = self

            // frcForFolders
            let fetchRequestFolders = NSFetchRequest<CdFolder>()
            fetchRequestFolders.sortDescriptors =
                [NSSortDescriptor(key: CdFolder.AttributeName.lastLookedAt, ascending: false)]
            fetchRequestFolders.entity = CdFolder.entity()
            if let cdAccount = imapConnection.cdAccount(moc: frcMoc) {
                fetchRequestFolders.predicate =
                    CdFolder.PredicateFactory.inAccount(cdAccount: cdAccount)
            } else {
                Log.shared.errorAndCrash("No CdAccount")
            }
            me.frcForFolders = NSFetchedResultsController(fetchRequest: fetchRequestFolders,
                                                          managedObjectContext: me.frcMoc,
                                                          sectionNameKeyPath: nil,
                                                          cacheName: nil)
            me.frcForFolders?.delegate = self
        }
    }

    func stopIdling() {
//        serializeQueue.addOperation { [weak self] in
//            guard let me = self else {
//                Log.shared.error("Lost myself") //BUFF: HERE
//                return
//            }
        let me = self
            me.lastCommand = .stopIdle
            me.next()
//        }
    }

    override func cancel() { //BUFF: HERE   
//        serializeQueue.addOperation { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash("Lost myself")
//                return
//            }
         let me = self
            me.lastCommand = .cancel
            me.next()
//        }
    }

    private func requestDone() {
        state = .requestedDone
        imapConnection.exitIdle()
        next()
    }

    private func next() {
        Log.shared.info("next() called with state %@, lastCommand %@",
                        state.debugString,
                        lastCommand.debugString)
        switch lastCommand {

        case .none:
            switch state {
            case .none:
            break // Nothing to do.
            case .requestedIdle:
                imapConnection.sendIdle()
            case .idling:
                break // Do nothing
            case .requestedDone:
                break // Do nothing
            case .idleFinished:
                waitForBackgroundTasksAndFinish()
            case .error:
                cancel()
            }
        case .stopIdle:
            switch state {
            case .none:
                cancel() //BUFF: OK?
            case .requestedIdle:
                // We have asked the server to idle and the client asked us to stop.
                // We do nothing, wait for server response and handle the clients
                // request after the server has answered.
                break
            case .idling:
                requestDone()
            case .requestedDone:
                break // Do nothing
            case .idleFinished:
                waitForBackgroundTasksAndFinish()
            case .error:
                cancel()
            }
        case .cancel:
            switch state {
            case .none:
                super.cancel()
            case .requestedIdle:
                // We have asked the server to idle and the client asked us to cancel.
                // We do nothing, wait for server response and handle the clients
                // request after the server has answered.
                break
            case .idling:
                requestDone()
            case .requestedDone:
                break // Do nothing
            case .idleFinished:
                waitForBackgroundTasksAndFinish()
            case .error:
                super.cancel()
            }
        }
    }

    override func main() {
        if !checkImapConnection() {
            waitForBackgroundTasksAndFinish()
            return
        }
        if !imapConnection.supportsIdle {
            markAsFinished()
            return
        }
        guard
            let frcMessages = frcForMessages,
            let frcFolders = frcForFolders
            else {
                Log.shared.errorAndCrash("FRC must exist @ this point.")
                markAsFinished()
                return
        }
        frcMoc.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            do {
                try frcMessages.performFetch()
                try frcFolders.performFetch()
            } catch {
                Log.shared.errorAndCrash("Error fetching: %@", error.localizedDescription)
            }
            me.process()
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

// MARK: - Private

extension ImapIdleOperation {

    private func process() {
        syncDelegate = ImapIdleDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        requestIdle()
    }

    private func requestIdle() {
        state = .requestedIdle
        next()
    }

    fileprivate func handleChangeOnServer() {
        stopIdling()
    }

    fileprivate func handleIdleEntered() {
        state = .idling
        next()
    }

    fileprivate func handleIdleFinished() {
        state = .idleFinished
        next()
    }

    fileprivate func handleError() {
        state = .error
        next()
    }

    fileprivate func handleLocalChangeHappened() {
        // The user changes a message (delted, flagged, moved, ...).
        // Exit idle mode to sync those changes to the IMAP server.
        Log.shared.info("%@: Local change reported", type(of: self).description())
        stopIdling()
    }
}

// MARK: - ImapIdleDelegate

class ImapIdleDelegate: DefaultImapConnectionDelegate {
    
    override func authenticationFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        errorHandler?.handle(error: ImapSyncOperationError.illegalState(#function))
        imapIdleOp()?.handleError()
    }

    override func connectionLost(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

    override func connectionTerminated(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

    override func connectionTimedOut(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleError()
    }

    override func badResponse(_ imapConection: ImapConnectionProtocol, response: String?) {
        imapIdleOp()?.handleError()
    }

    override func actionFailed(_ imapConection: ImapConnectionProtocol, response: String?) {
        imapIdleOp()?.handleError()
    }

    override func idleEntered(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        Log.shared.info("IDLE mode entered")
        imapIdleOp()?.handleIdleEntered()
    }


    override func idleChangeOnServer(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        imapIdleOp()?.handleChangeOnServer()
    }

    override func idleFinished(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        Log.shared.info("IDLE mode finished")
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

// MARK: - NSFetchedResultsControllerDelegate

extension ImapIdleOperation: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We are using a trivial implementation until we need somthing more sofisticated.
        // Any change on any CdMessage will stop idle mode.
        if controller == frcForMessages {
            handleLocalChangeHappened()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        guard controller == frcForFolders else {
            // Messages are handled in controllerDidChangeContent.
            return
        }
        if type == .move {
            // We are sorting folders by lastLookat date, thus the order changes if a different
            // folder is entered by the user (folders last lookat has been updated).
            handleLocalChangeHappened()
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // do nothing
    }
}
