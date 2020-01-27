//
//  EmailDetailViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

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

    weak var selectionChangeDelegate: EmailDetailViewModelSelectionChangeDelegate?

    init(messageQueryResults: MessageQueryResults,
         delegate: EmailDisplayViewModelDelegate? = nil) {
        super.init(messageQueryResults: messageQueryResults)
        self.messageQueryResults.rowDelegate = self
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

    /// You can call this to show a specific, user selected message instead of instanziating a
    /// new EmailDetailView.
    /// - Parameter indexPath: indexPath to select
    public func select(itemAt indexPath: IndexPath) {
        delegate?.select(itemAt: indexPath)
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
            return #imageLiteral(resourceName: "icon-flagged")
        } else {
            return #imageLiteral(resourceName: "icon-unflagged")
        }
    }

    /// - Parameter indexPath: indexPath of the cell to show the pEp rating for.
    /// - returns: pEp rating for cell at given indexPath
    public func pEpRating(forItemAt indexPath: IndexPath) -> PEPRating {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return .undefined
        }
        return message.pEpRating()
    }

    /// - Parameter indexPath: indexPath of the cell to compute result for.
    /// - returns:  Whether or not to show privacy icon for cell at given indexPath
    public func shouldShowPrivacyStatus(forItemAt indexPath: IndexPath) -> Bool {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return false
        }
        let handshakeCombos = message.handshakeActionCombinations()
        guard !handshakeCombos.isEmpty else {
            return false
        }
        return true
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
        if !message.imapFlags.seen {
            message.markAsSeen()
        }
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

    private func isHandshakePossible(forItemAt indexPath: IndexPath) -> Bool {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return false
        }
        let handshakeCombos = message.handshakeActionCombinations()
        guard !handshakeCombos.isEmpty else {
            return false
        }
        return true
    }
}

// MARK: - QueryResultsIndexPathRowDelegate

extension EmailDetailViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        handleIndexPathIsBeforeCurrentlyShownMessage(insertedIndexPath: indexPath)
        delegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
    }

    func didUpdateRow(indexPath: IndexPath) {
        if pathsForMessagesMarkedForRedecrypt.contains(indexPath) {
            if let message = message(representedByRowAt: indexPath),
                !message.pEpRating().isUnDecryptable() {
                guard let delegate = delegate as? EmailDetailViewModelDelegate else {
                    Log.shared.errorAndCrash("Inbvalid state")
                    return
                }
                // Previously undecryptable message has successfully been decrypted.
                delegate.isNotUndecryptableAnyMore(indexPath: indexPath)
            }
            pathsForMessagesMarkedForRedecrypt = pathsForMessagesMarkedForRedecrypt.filter { $0 != indexPath }
        }
        delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
    }

    func didDeleteRow(indexPath: IndexPath) {
        handleIndexPathIsBeforeCurrentlyShownMessage(insertedIndexPath: indexPath)
        delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
    }

    func willChangeResults() {
        updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = false
        delegate?.willReceiveUpdates(viewModel: self)
    }

    func didChangeResults() {
        delegate?.allUpdatesReceived(viewModel: self)
    }

    private func handleIndexPathIsBeforeCurrentlyShownMessage(insertedIndexPath: IndexPath) {
        if let currentlyShownIndex = indexPathForCellDisplayedBeforeUpdating,
            insertedIndexPath.row <= currentlyShownIndex.row {
            updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = true
        }
    }
}
