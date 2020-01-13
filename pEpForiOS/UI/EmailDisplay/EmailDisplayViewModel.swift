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
import PEPObjCAdapterFramework

protocol EmailDisplayViewModelProtocol {
    var delegate: EmailDisplayViewModelDelegate? { get set }
    var messageQueryResults: MessageQueryResults { get }
    var rowCount: Int { get }
    func startMonitoring()

    func informDelegateToReloadData()
    //Abstract. Has to be overridden.
    func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])  -> MoveToAccountViewModel?
    //!!!: this should be internal (not part of the protocol). VC and Cells MUST not know the model (Message).
    func message(representedByRowAt indexPath: IndexPath) -> Message?

    func delete(messages: [Message])

    func replyAllPossibleChecker(forItemAt indexPath: IndexPath) -> ReplyAllPossibleCheckerProtocol?
}

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

    func select(itemAt indexPath: IndexPath)
}

// MARK: - EmailDisplayViewModel

/// Base class for MessageQueryResults driven email display view models.
class EmailDisplayViewModel: EmailDisplayViewModelProtocol {

    // MARK: - Life Cycle

    init(delegate: EmailDisplayViewModelDelegate? = nil, messageQueryResults: MessageQueryResults) {
        self.delegate = delegate
        // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
        self.messageQueryResults = messageQueryResults
    }

    // MARK: - EmailDisplayViewModelProtocol

    var messageQueryResults: MessageQueryResults

    public weak var delegate: EmailDisplayViewModelDelegate?

    public func startMonitoring() {
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("MessageQueryResult crash")
        }
    }

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

    public func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])  -> MoveToAccountViewModel? {
        fatalError("Must be overridden")
    }

    public func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messageQueryResults[indexPath.row]
    }

    public func informDelegateToReloadData() {
        delegate?.reloadData(viewModel: self)
    }

    public func delete(messages: [Message]) {
        Message.imapDelete(messages: messages)
    }

    public func replyAllPossibleChecker(forItemAt indexPath: IndexPath) -> ReplyAllPossibleCheckerProtocol? {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return nil
        }
        return ReplyAllPossibleChecker(messageToReplyTo: message)
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

    func composeViewModel(withOriginalMessageAt indexPath: IndexPath,
                          composeMode: ComposeUtil.ComposeMode? = nil) -> ComposeViewModel {
        let message = messageQueryResults[indexPath.row]
        let composeVM = ComposeViewModel(composeMode: composeMode,
                                         originalMessage: message)
        return composeVM
    }
}
