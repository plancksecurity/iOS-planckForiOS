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
    func informDelegateToReloadData()
    func startMonitoring()
    var rowCount: Int { get }
    //Abstract. Has to be overridden.
    func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])  -> MoveToAccountViewModel?
    //!!!: this should be internal (not part of the protocol). VC and Cells MUST not know the model (Message).
    func message(representedByRowAt indexPath: IndexPath) -> Message?

    func delete(messages: [Message])

    func replyAllPossibleChecker(forItemAt indexPath: IndexPath) -> ReplyAllPossibleCheckerProtocol?
}

protocol EmailDisplayViewModelDelegate: class/*, TableViewUpdate*/ {
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
    var messageQueryResults: MessageQueryResults
    let folderToShow: DisplayableFolderProtocol
    private var selectedItems: Set<IndexPath>?

    // MARK: - Life Cycle

    init(messageQueryResults: MessageQueryResults? = nil, folderToShow: DisplayableFolderProtocol) {
        self.folderToShow = folderToShow

        // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
        self.messageQueryResults = messageQueryResults ?? MessageQueryResults(withFolder: folderToShow,
                                                                              filter: nil,
                                                                              search: nil)
    }

    // MARK: - EmailDisplayViewModelProtocol

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

    func folderIsDraftOrOutbox(_ parentFoldder: Folder) -> Bool {
        return folderIsDraft(parentFoldder) || folderIsOutbox(parentFoldder)
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

    private func folderIsDraftsOrOutbox(_ parentFolder: Folder?) -> Bool {
        return folderIsDraft(parentFolder) || folderIsOutbox(parentFolder)
    }
}

// MARK: - ComposeViewModel

extension EmailDisplayViewModel {
    func composeViewModel(withOriginalMessageAt indexPath: IndexPath,
                          composeMode: ComposeUtil.ComposeMode? = nil) -> ComposeViewModel {
        let message = messageQueryResults[indexPath.row]
        let composeVM = ComposeViewModel(resultDelegate: self,
                                         composeMode: composeMode,
                                         originalMessage: message)
        return composeVM
    }
}

// MARK: - ComposeViewModelResultDelegate

extension EmailDisplayViewModel: ComposeViewModelResultDelegate {
    func composeViewModelDidComposeNewMail(message: Message) {
        if folderIsDraftsOrOutbox(message.parent){
            informDelegateToReloadData()
        }
    }

    func composeViewModelDidDeleteMessage(message: Message) { //BUFF: That should be handled by QRC, no?
        if folderIsDraftOrOutbox(message.parent) {
            informDelegateToReloadData()
        }
    }

    func composeViewModelDidModifyMessage(message: Message) { //BUFF: That should be handled by QRC, no?
        if folderIsDraft(message.parent){
            informDelegateToReloadData()
        }
    }
}
