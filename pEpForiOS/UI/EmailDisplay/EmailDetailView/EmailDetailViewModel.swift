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
    //BUFF: All moved to EmailDisplayViewModelDelegate. Will be filled with list specific stuff soon. Stay tuned.

    /// `emailListViewModel(viewModel:didUpdateDataAt:)` should not reload the cell but update the
    /// flags ad such.
    /// There is only one case where the cell has to be reloaded: A mail is shown as undecryptable
    /// and has been decrypted afterwards.
    /// - Parameter indexPath: indexpath of mail to reload
    func isNotUndecryptableAnyMore(indexPath: IndexPath)
}

/// Reports back currently shown email changes
protocol EmailDetailViewModelSelectionChangeDelegate: class {
    func emailDetailViewModel(emailDetailViewModel: EmailDetailViewModel,
                              didSelectItemAt indexPath: IndexPath)
}

// 
class EmailDetailViewModel: EmailDisplayViewModel {
    // Property coll delegate
    weak var delegate: EmailDetailViewModelDelegate?
    weak var selectionChangeDelegate: EmailDetailViewModelSelectionChangeDelegate?

    init(messageQueryResults: MessageQueryResults? = nil,
         delegate: EmailDisplayViewModelDelegate? = nil,
         folderToShow: DisplayableFolderProtocol) {
        super.init(messageQueryResults: messageQueryResults,
                   folderToShow: folderToShow)
        self.messageQueryResults.rowDelegate = self
    }

    public func replaceMessageQueryResults(with qrc: MessageQueryResults) {
        messageQueryResults = qrc
        messageQueryResults.rowDelegate = self
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }

    override func informDelegateToReloadData() {
        delegate?.reloadData(viewModel: self)
    }

    //

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
        Message.imapDelete(messages: [message])

    }

    private var pathsForMessagesMarkedForRedecrypt = [IndexPath]()

    public func handleEmailShown(forItemAt indexPath: IndexPath) {
        markForRedecryptionIfNeeded(messageRepresentedby: indexPath)
        markSeenIfNeeded(messageRepresentedby: indexPath)
        selectionChangeDelegate?.emailDetailViewModel(emailDetailViewModel: self,
                                                      didSelectItemAt: indexPath)
    }

    public func markForRedecryptionIfNeeded(messageRepresentedby indexPath: IndexPath) {
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

    private func markSeenIfNeeded(messageRepresentedby indexPath: IndexPath) {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return
        }
        if !message.imapFlags.seen {
            message.markAsSeen()
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


    //
}

// MARK: - QueryResultsIndexPathRowDelegate

extension EmailDetailViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
    }

    func didUpdateRow(indexPath: IndexPath) {
        if pathsForMessagesMarkedForRedecrypt.contains(indexPath) {
            if let message = message(representedByRowAt: indexPath),
                !message.pEpRating().isUnDecryptable() {
                // Previously undecryptable message has successfully been decrypted.
                delegate?.isNotUndecryptableAnyMore(indexPath: indexPath)
            }
            pathsForMessagesMarkedForRedecrypt = pathsForMessagesMarkedForRedecrypt.filter { $0 != indexPath }
        }
        delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
    }

    func didDeleteRow(indexPath: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
    }

    func willChangeResults() {
        delegate?.willReceiveUpdates(viewModel: self)
    }

    func didChangeResults() {
        delegate?.allUpdatesReceived(viewModel: self)
    }
}

// MARK: - Destination VM Factory

extension EmailDetailViewModel {

    public func moveToAccountViewModel(forMessageRepresentedByItemAt indexPath: IndexPath) -> MoveToAccountViewModel? {
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
        return ComposeViewModel(resultDelegate: nil,
                                composeMode: composeMode,
                                prefilledTo: nil,
                                originalMessage: msg)
    }
}
