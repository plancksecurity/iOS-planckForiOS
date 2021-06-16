//
//  EmailDisplayViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import MessageModel

protocol EmailDisplayViewModelDelegate: class {
    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didInsertDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didUpdateDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didRemoveDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath)
    func willReceiveUpdates(viewModel: EmailDisplayViewModel)
    func allUpdatesReceived(viewModel: EmailDisplayViewModel)
    func reloadData(viewModel: EmailDisplayViewModel)
}

/// Base class for MessageQueryResults driven email display view models.
/// All ViewModels that are showing messages that are fetched and monitored by MessageQueryResults
/// should subclass from this.
class EmailDisplayViewModel {

    // MARK: - Life Cycle

    init(delegate: EmailDisplayViewModelDelegate? = nil, messageQueryResults: MessageQueryResults) {
        self.delegate = delegate
        // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
        self.messageQueryResults = messageQueryResults
    }

    /// Message query to display messages for
    var messageQueryResults: MessageQueryResults

    /// The *V*iew in our MVC
    public weak var delegate: EmailDisplayViewModelDelegate?

    /// Starts monitoring the given database query.
    public func startMonitoring() {
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("MessageQueryResult crash")
        }
    }

    public func handleViewDidLoad() {
        startMonitoring()
    }

    /// Number of messages
    public var rowCount: Int {
        if messageQueryResults.filter?.accountsEnabledStates.count == 0 {
            // This is a dirty hack to workaround that we are (inccorectly) showning an
            // EmailListView without having an account.
            return 0
        }
        do {
            return try messageQueryResults.count()
        } catch {
            // messageQueryResults has not been started yet. That's OK.
            return 0
        }
    }

    //Abstract. Has to be overridden.
    public func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])  -> MoveToAccountViewModel? {
        fatalError("Must be overridden")
    }

    //!!!: this should be internal (not part of the protocol). VC and Cells MUST not know the model (Message).
    /// - Parameter indexPath: indexPath of the cell to get the message it represents for.
    /// - returns:  `nil` if `indexPath` is out of the current queryResults bounds, otherwize the
    ///             Message represented by the given `indexPath`?.
    public func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messageQueryResults[indexPath.row]
    }

    /// - Parameter indexPath: indexPath of message to configure ReplyAllPossibleChecker with
    /// - returns: `ReplyAllPossibleChecker` configured for message represented by
    ///             given `indexPath`.
    public func replyAllPossibleChecker(forItemAt indexPath: IndexPath) -> ReplyAllPossibleCheckerProtocol? {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return nil
        }
        return ReplyAllPossibleChecker(messageToReplyTo: message)
    }

    // MARK: - Stuff that should be visible for subclasses only

    func informDelegateToReloadData() {
        delegate?.reloadData(viewModel: self)
    }

    func delete(messages: [Message]) {
        Message.imapDelete(messages: messages)
    }
}

// MARK: - FolderType Utils

extension EmailDisplayViewModel {

    func getParentFolder(forMessageAt index: Int) -> Folder {
        return messageQueryResults[index].parent
    }

    func folderIsOutbox(_ parentFolder: Folder?) -> Bool {
        guard let folder = parentFolder else {
            Log.shared.errorAndCrash("No parent.")
            return false
        }
        return folderIsOutbox(folder)
    }

    private func folderIsOutbox(_ parentFolder: Folder) -> Bool {
        return parentFolder.folderType == .outbox
    }

    private func folderIsDraft(_ parentFolder: Folder) -> Bool {
        return parentFolder.folderType == .drafts
    }

    private func folderIsDraft(_ parentFolder: Folder?) -> Bool {
        guard let folder = parentFolder else {
            Log.shared.errorAndCrash("No parent.")
            return false
        }
        return folderIsDraft(folder)
    }

    func folderIsDraftsOrOutbox(_ parentFolder: Folder?) -> Bool {
        return folderIsDraft(parentFolder) || folderIsOutbox(parentFolder)
    }
}

// MARK: - ViewModel Factory

extension EmailDisplayViewModel {

    /// Destination VM Factory - Compose VM
    /// - Parameter indexPath: indexPath of the cell to show ComposeView view for.
    /// - returns:  ComposeViewModel configured for given compose mode for message represented by
    ///             the given indexPath
    func composeViewModel(forMessageRepresentedByItemAt indexPath: IndexPath,
                          composeMode: ComposeUtil.ComposeMode) -> ComposeViewModel? {
        guard let msg = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No Message")
            return nil
        }
        return ComposeViewModel(composeMode: composeMode,
                                prefilledTo: nil,
                                originalMessage: msg)
    }
}
