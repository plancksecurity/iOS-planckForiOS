//
//  EmailDetailViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

protocol EmailDetailViewModelDelegate: EmailDisplayViewModelDelegate {

    /// `emailListViewModel(viewModel:didUpdateDataAt:)` should not reload the cell but update the
    /// flags and such.
    /// This callback is to handle the only case where the cell has to be reloaded: A mail is
    /// shown as undecryptable and has been decrypted while displaying it.
    /// - Parameter indexPath: indexpath of mail to reload
    func isNotUndecryptableAnyMore(indexPath: IndexPath)
}

/// Reports back currently shown email changes.
protocol EmailDetailViewModelSelectionChangeDelegate: class {
    /// Called when the currently shown message changes
    func emailDetailViewModel(emailDetailViewModel: EmailDetailViewModel,
                              didSelectItemAt indexPath: IndexPath)
}

class EmailDetailViewModel: EmailDisplayViewModel {
    /// Used to figure out whether or not the currently displayed message has been decrypted while
    /// being shown to the user.
    private var pathsForMessagesMarkedForRedecrypt = [IndexPath]()
    /// Remember the message the user is viewing
    private var lastShownMessage: Message?
    /// Whether or not a message has been inserted or removed before the currently shown message.
    /// Used to figure out if we need to scroll to the currently viewed message after update.
    private var updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = false
    /// Use in queryResultsDelegate to serialize calls to VC to guarantee correct order.
    private let queryResultsDelegateHandlingQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = "EmailDetailViewModel-queryResultsDelegateHandlingQueue)"
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    weak var selectionChangeDelegate: EmailDetailViewModelSelectionChangeDelegate?

    init(messageQueryResults: MessageQueryResults,
         delegate: EmailDisplayViewModelDelegate? = nil) {
        super.init(messageQueryResults: messageQueryResults)
        self.messageQueryResults.rowDelegate = self
    }
    
    /// TrustManagementViewModel getter
    var trustManagementViewModel: TrustManagementViewModel? {
        get {
            guard let message = lastShownMessage else {
                Log.shared.error("Message not found")
                return nil
            }
            return TrustManagementViewModel(message: message, pEpProtectionModifyable: false)
        }
    }

    /// Replaces and uses the currently used message query with the given one. The displayed
    /// messages get updated automatically.
    /// - Parameter qrc: messages to display to the user
    public func replaceMessageQueryResults(with qrc: MessageQueryResults) throws {
        messageQueryResults = qrc
        messageQueryResults.rowDelegate = self
        try messageQueryResults.startMonitoring()
        reset()
        delegate?.reloadData(viewModel: self)
    }

    /// Action handling
    /// - Parameter indexPath: indexPath of cell the flag button has been pressed for
    public func handleFlagButtonPress(for indexPath: IndexPath) {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        let flags = message.imapFlags
        flags.flagged = !flags.flagged
        message.imapFlags = flags
        Session.main.commit()
    }

    /// Action handling
    /// - Parameter indexPath: indexPath of cell the destructive button has been pressed for
    public func handleDestructiveButtonPress(for indexPath: IndexPath) {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        delete(messages: [message])
    }

    /// Must be called whenever a new message has been displayed.
    /// - Parameter indexPath: indexPath of the cell that has been displayed
    public func handleEmailShown(forItemAt indexPath: IndexPath) {
        lastShownMessage = message(representedByRowAt: indexPath)
        markForRedecryptionIfNeeded(messageRepresentedBy: indexPath)
        markSeenIfNeeded(messageRepresentedby: indexPath)
        selectionChangeDelegate?.emailDetailViewModel(emailDetailViewModel: self,
                                                      didSelectItemAt: indexPath)
    }

    /// The indexpath of the last displayerd message.
    /// Used to scroll to after the data soure has been updated.
    /// Returns `nil` in case the previously shown message is not contained in the query results
    /// any more after updating the data source.
    public var indexPathForCellDisplayedBeforeUpdating: IndexPath? {
        guard
            let messageShownBeforeUpdating = lastShownMessage,
            !messageShownBeforeUpdating.isDeleted
            else {
                // Nothing to do
                return nil
        }
        for i in 0..<messageQueryResults.all.count {
            let testee = messageQueryResults[i]
            if testee == messageShownBeforeUpdating {
                return IndexPath(item: i, section: 0)
            }
        }
        return nil
    }

    /// Scroll to `indexPathForCellDisplayedBeforeUpdating` after the collection has been updated
    /// (only) if this is true.
    public var shouldScrollBackToCurrentlyViewdCellAfterUpdate: Bool {
        return updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage
    }

    /// - Parameter indexPath: indexPath of the cell to show the destructive button for.
    /// - returns: The icon to use for the destruktive button (delete, archive, ...)
    public func destructiveButtonIcon(forMessageAt indexPath: IndexPath?) -> UIImage? {
        guard
            let path = indexPath,
            let msg = message(representedByRowAt: path) else {
                Log.shared.info("Nothing shown")
                return nil
        }
        if msg.parent.defaultDestructiveActionIsArchive {
            return #imageLiteral(resourceName: "folders-icon-archive")
        } else {
            return #imageLiteral(resourceName: "folders-icon-trash")
        }
    }

    /// - Parameter indexPath: indexPath of the cell to show the flagged state button for.
    /// - returns: The icon to use for the flagging button of cell at indexPath
    public func flagButtonIcon(forMessageAt indexPath: IndexPath?) -> UIImage? {
        guard
            let path = indexPath,
            let msg = message(representedByRowAt: path) else {
                Log.shared.info("Nothing shown")
                return nil
        }
        
        if msg.imapFlags.flagged {
            return UIImage(named: "pEpForiOS-icon-flagged")
        } else {
            return UIImage(named: "pEpForiOS-icon-unflagged")
        }
    }

    /// - Parameter indexPath: indexPath of the cell to show the pEp rating for.
    /// - returns: pEp rating for cell at given indexPath
    public func pEpRating(forItemAt indexPath: IndexPath, completion: @escaping (Rating) -> Void) {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            completion(.undefined)
            return
        }
        return message.pEpRating { (rating) in
            DispatchQueue.main.async {
                completion(rating)
            }
        }
    }

    /// - Parameter indexPath: indexPath of the cell to compute result for.
    /// - returns:  Whether or not to show privacy icon for cell at given indexPath
    public func shouldShowPrivacyStatus(forItemAt indexPath: IndexPath,
                                        completion: @escaping (Bool)->Void){
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            completion(false)
            return
        }
        TrustManagementUtil().handshakeCombinations(message: message) { (handshakeCombos) in
            completion(handshakeCombos.isEmpty ? false : true)
        }
    }

    /// Destination VM Factory - Move To Folder VM
    /// - Parameter indexPath: indexPath of the cell to show "moveToFolder" view for.
    /// - returns:  MoveToAccountViewModel configured for message represented by the given indexPath
    public func getMoveToFolderViewModel(forMessageRepresentedByItemAt indexPath: IndexPath) -> MoveToAccountViewModel? {
        guard let msg = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("Nothing to move?")
            return nil
        }
        return MoveToAccountViewModel(messages: [msg])
    }

    /// The number of rows (not yet displayed to the user) before we want to fetch older messages.
    /// A balance between good user experience (have data in time,
    /// ideally before the user has scrolled to the last row) and memory usage has to be found.
    private let numRowsBeforeLastToTriggerFetchOder = 1

    /// Figures out whether or not fetching of older messages should be requested.
    /// Takes numRowsBeforeLastToTriggerFetchOder into account,
    ///
    /// - Parameter row: number of displayed tableView row to base computation on
    /// - Returns: true if fetch older messages should be requested, false otherwize
    private func triggerFetchOlder(lastDisplayedRow row: Int) -> Bool {
        return row >= rowCount - numRowsBeforeLastToTriggerFetchOder
    }

    // When the user has scrolled down (almost) to the end, we fetch older emails.
    /// - Parameter indexPath: indexpath to pontetionally fetch older messages for
    public func fetchOlderMessagesIfRequired(forIndexPath indexPath: IndexPath) {
        if !triggerFetchOlder(lastDisplayedRow: indexPath.row) {
            return
        }

        guard let msg = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No message from which to get the folder")
            return
        }

        msg.parent.fetchOlder(completion: nil)
    }

    /// Retrieves an EmailViewModel for the message in the provided indexPath
    /// - Parameters:
    ///   - indexPath: The indexPath of the message
    ///   - delegate: The email view model delegate.
    /// - Returns: The Email View Model
    public func emailViewModel(withMessageRepresentedByRowAt indexPath: IndexPath, delegate: EmailViewModelDelegate) -> EmailViewModel? {
        guard let m = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("Message not found")
            return nil
        }
        return EmailViewModel(message: m, delegate: delegate)
    }
}

// MARK: - Private

extension EmailDetailViewModel {

    /// Resets bookholding vars
    private func reset() {
        pathsForMessagesMarkedForRedecrypt = [IndexPath]()
        lastShownMessage = nil
        updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = false
    }

    private func markSeenIfNeeded(messageRepresentedby indexPath: IndexPath) {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        message.markAsSeen()
    }

    private func markForRedecryptionIfNeeded(messageRepresentedBy indexPath: IndexPath) {
        // rm previously stored IndexPath for this message.
        pathsForMessagesMarkedForRedecrypt = pathsForMessagesMarkedForRedecrypt.filter { $0 != indexPath }
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        // The user may be about to view an yet undecrypted message.
        // If so, try again to decrypt it.
        if message.markForRetryDecryptIfUndecryptable() {
            pathsForMessagesMarkedForRedecrypt.append(indexPath)
        }
    }
}

// MARK: - QueryResultsIndexPathRowDelegate

extension EmailDetailViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                // Do nothing ...
                return
            }
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                me.handleIndexPathIsBeforeCurrentlyShownMessage(insertedIndexPath: indexPath)
                me.delegate?.emailListViewModel(viewModel: me, didInsertDataAt: [indexPath])
                group.leave()
            }
            group.wait()
        }
    }

    func didUpdateRow(indexPath: IndexPath) {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                // Do nothing ...
                return
            }
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                var messageRating: Rating? = nil
                let innerGroup = DispatchGroup()
                if let message = me.message(representedByRowAt: indexPath) {
                    innerGroup.enter()
                    message.pEpRating { (rating) in
                        messageRating = rating
                        innerGroup.leave()
                    }
                }
                innerGroup.notify(queue: DispatchQueue.main) {
                    defer { group.leave() }
                    if me.pathsForMessagesMarkedForRedecrypt.contains(indexPath) {
                        if let rating = messageRating, !rating.isUnDecryptable() {
                            guard let delegate = me.delegate as? EmailDetailViewModelDelegate else {
                                Log.shared.errorAndCrash("Inbvalid state")
                                return
                            }
                            // Previously undecryptable message has successfully been decrypted.
                            delegate.isNotUndecryptableAnyMore(indexPath: indexPath)
                        }
                        me.pathsForMessagesMarkedForRedecrypt = me.pathsForMessagesMarkedForRedecrypt.filter { $0 != indexPath }
                    }
                    me.delegate?.emailListViewModel(viewModel: me, didUpdateDataAt: [indexPath])
                }
            }
            group.wait()
        }
    }

    func didDeleteRow(indexPath: IndexPath) {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                // Do nothing ...
                return
            }
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                defer { group.leave() }
                me.handleIndexPathIsBeforeCurrentlyShownMessage(insertedIndexPath: indexPath)
                me.delegate?.emailListViewModel(viewModel: me, didRemoveDataAt: [indexPath])
            }
            group.wait()
        }
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                // Do nothing ...
                return
            }
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                defer { group.leave() }
                me.delegate?.emailListViewModel(viewModel: me, didMoveData: from, toIndexPath: to)
            }
            group.wait()
        }
    }

    func willChangeResults() {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                // Do nothing ...
                return
            }
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                defer { group.leave() }
                me.updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = false
                me.delegate?.willReceiveUpdates(viewModel: me)
            }
            group.wait()
        }
    }

    func didChangeResults() {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                // Do nothing ...
                return
            }
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                defer { group.leave() }
                me.delegate?.allUpdatesReceived(viewModel: me)
            }
            group.wait()
        }
    }

    private func handleIndexPathIsBeforeCurrentlyShownMessage(insertedIndexPath: IndexPath) {
        if let currentlyShownIndex = indexPathForCellDisplayedBeforeUpdating,
            insertedIndexPath.row <= currentlyShownIndex.row {
            updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = true
        }
    }
}
