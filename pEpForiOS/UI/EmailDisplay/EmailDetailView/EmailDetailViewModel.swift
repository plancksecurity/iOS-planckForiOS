//
//  EmailDetailViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

protocol EmailDetailViewModelProtocol: EmailDisplayViewModelProtocol {
    func replaceMessageQueryResults(with qrc: MessageQueryResults) throws
    func select(itemAt indexPath: IndexPath)
    func handleFlagButtonPress(for indexPath: IndexPath)

    func handleDestructiveButtonPress(for indexPath: IndexPath)

    func handleEmailShown(forItemAt indexPath: IndexPath)

    var indexPathForCellDisplayedBeforeUpdating: IndexPath? { get }

    /// Scroll to `indexPathForCellDisplayedBeforeUpdating` after the collection has been updated
    /// (only) if this is true.
    var shouldScrollBackToCurrentlyViewdCellAfterUpdate: Bool { get }

    func markForRedecryptionIfNeeded(messageRepresentedBy indexPath: IndexPath)

    func destructiveButtonIcon(forMessageAt indexPath: IndexPath?) -> UIImage?

    func flagButtonIcon(forMessageAt indexPath: IndexPath?) -> UIImage?

    func pEpRating(forItemAt indexPath: IndexPath) -> PEPRating

    func canShowPrivacyStatus(forItemAt indexPath: IndexPath) -> Bool

    func isHandshakePossible(forItemAt indexPath: IndexPath) -> Bool

    /// Destination VM Factory - Move To Folder
    func getMoveToFolderViewModel(forMessageRepresentedByItemAt indexPath: IndexPath) -> MoveToAccountViewModel?
    /// Destination VM Factory - Compose
    func composeViewModel(forMessageRepresentedByItemAt indexPath: IndexPath,
                          composeMode: ComposeUtil.ComposeMode) -> ComposeViewModel?
}

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
    func emailDetailViewModel(emailDetailViewModel: EmailDetailViewModelProtocol,
                              didSelectItemAt indexPath: IndexPath)
}

class EmailDetailViewModel: EmailDisplayViewModel, EmailDetailViewModelProtocol {
    /// Used to figure out whether or not the currently displayed message has been decrypted while
    /// being shown to the user.
    private var pathsForMessagesMarkedForRedecrypt = [IndexPath]()
    /// Remember the message the user is viewing
    private var lastShownMessage: Message?
    /// Whether or not a message has been inserted or removed before the currently shown message.
    /// Used to figure out if we need to scroll to the currently viewed message after update.
    private var updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage = false

    weak var selectionChangeDelegate: EmailDetailViewModelSelectionChangeDelegate?

    init(messageQueryResults: MessageQueryResults, delegate: EmailDisplayViewModelDelegate? = nil) {
        super.init(messageQueryResults: messageQueryResults)
        self.messageQueryResults.rowDelegate = self
    }

    // MARK: - EmailDetailViewModelProtocol

    public func replaceMessageQueryResults(with qrc: MessageQueryResults) throws {
        messageQueryResults = qrc
        messageQueryResults.rowDelegate = self
        try messageQueryResults.startMonitoring()
        reset()
        delegate?.reloadData(viewModel: self)
    }

    public func select(itemAt indexPath: IndexPath) {
        delegate?.select(itemAt: indexPath)
    }

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

    public func handleDestructiveButtonPress(for indexPath: IndexPath) {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        delete(messages: [message])
    }

    public func handleEmailShown(forItemAt indexPath: IndexPath) {
        lastShownMessage = message(representedByRowAt: indexPath)
        markForRedecryptionIfNeeded(messageRepresentedBy: indexPath)
        markSeenIfNeeded(messageRepresentedby: indexPath)
        selectionChangeDelegate?.emailDetailViewModel(emailDetailViewModel: self,
                                                      didSelectItemAt: indexPath)
    }

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
    
    public var shouldScrollBackToCurrentlyViewdCellAfterUpdate: Bool {
        return updateInsertedOrRemovedMessagesBeforeCurrentlyShownMessage
    }

    public func markForRedecryptionIfNeeded(messageRepresentedBy indexPath: IndexPath) {
        // rm previously stored IndexPath for this message.
        pathsForMessagesMarkedForRedecrypt = pathsForMessagesMarkedForRedecrypt.filter { $0 != indexPath }
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        /// The user may be about to view an yet undecrypted message.
        // If so, try again to decrypt it.
        if message.markForRetryDecryptIfUndecryptable() {
            pathsForMessagesMarkedForRedecrypt.append(indexPath)
        }
    }

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

    public func pEpRating(forItemAt indexPath: IndexPath) -> PEPRating {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return .undefined
        }
        return message.pEpRating()
    }


    public func canShowPrivacyStatus(forItemAt indexPath: IndexPath) -> Bool {
        return isHandshakePossible(forItemAt: indexPath)
    }

    public func isHandshakePossible(forItemAt indexPath: IndexPath) -> Bool {
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

    public func getMoveToFolderViewModel(forMessageRepresentedByItemAt indexPath: IndexPath) -> MoveToAccountViewModel? {
        guard let msg = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("Nothing to move?")
            return nil
        }
        return MoveToAccountViewModel(messages: [msg])
    }

    public func composeViewModel(forMessageRepresentedByItemAt indexPath: IndexPath,
                                 composeMode: ComposeUtil.ComposeMode) -> ComposeViewModel? {
        guard let msg = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("Nothing to move?")
            return nil
        }
        return ComposeViewModel(composeMode: composeMode,
                                prefilledTo: nil,
                                originalMessage: msg)
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
