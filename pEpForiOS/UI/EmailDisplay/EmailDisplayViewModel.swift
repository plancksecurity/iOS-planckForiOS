//
//  EmailDisplayViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

//
//  EmailListViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel
import PEPObjCAdapterFramework

// MARK: - EmailDisplayViewModelDelegate

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
}

// MARK: - EmailDisplayViewModel

/// Base class for MessageQueryResults driven email display view models.
class EmailDisplayViewModel {
//    let contactImageTool = IdentityImageTool()
    var messageQueryResults: MessageQueryResults

//    var lastSearchTerm = ""
//    var updatesEnabled = true

//    weak var delegate: EmailDisplayViewModelDelegate? //BUFF: rm var

    let folderToShow: DisplayableFolderProtocol
    private var selectedItems: Set<IndexPath>?

    // MARK: - Life Cycle

    init(messageQueryResults: MessageQueryResults? = nil,
         folderToShow: DisplayableFolderProtocol) {
        self.folderToShow = folderToShow

        // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
        self.messageQueryResults = messageQueryResults ?? MessageQueryResults(withFolder: folderToShow,
                                                                              filter: nil,
                                                                              search: nil)
//        self.messageQueryResults.rowDelegate = self
    }

    func startMonitoring() {
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("MessageQueryResult crash")
        }
    }

    var folderName: String {
        return Folder.localizedName(realName: folderToShow.title)
    }

    func isEditable(messageAt indexPath: IndexPath) -> Bool {
        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .drafts {
            return true
        } else {
            return false
        }
    }

    func isSelectable(messageAt indexPath: IndexPath) -> Bool {
        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .outbox {
            return false
        } else {
            return true
        }
    }

    // MARK: - Public Data Access & Manipulation

    func viewModel(for index: Int) -> MessageViewModel? {
        let messageViewModel = MessageViewModel(with: messageQueryResults[index])
        return messageViewModel
    }

    var rowCount: Int {
        if messageQueryResults.filter?.accountsEnabledStates.count == 0 {
            // This is a dirty hack to workaround that we are (inccorectly) showning an
            // EmailListView without having an account.
            return 0
        }
        do {
            return try messageQueryResults.count()
        } catch {
            return 0
        }
    }

    func pEpRatingColorImage(forCellAt indexPath: IndexPath) -> UIImage? {
        guard let count = try? messageQueryResults.count(), indexPath.row < count else {
            // The model has been updated.
            return nil
        }
        let message = messageQueryResults[indexPath.row]
        let color = PEPUtils.pEpColor(pEpRating: message.pEpRating())
        if color != PEPColor.noColor {
            return color.statusIconForMessage()
        } else {
            return nil
        }
    }

    func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])
        -> MoveToAccountViewModel? {
            fatalError("Must be overridden")
    }

    func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messageQueryResults[indexPath.row]
    }


    func informDelegateToReloadData() {
        fatalError("Must be overridden")
    }


    public func shouldShowToolbarEditButtons() -> Bool {
        switch folderToShow {
        case is VirtualFolderProtocol:
            return true
        case let folder as Folder:
            return folder.folderType != .outbox && folder.folderType != .drafts
        default:
            return true
        }
    }

    func delete(messages: [Message]) { //BUFF: n pr
        Message.imapDelete(messages: messages)
    }

    //
    public func replyAllPossibleChecker(forItemAt indexPath: IndexPath) -> ReplyAllPossibleCheckerProtocol? {
        guard let message = message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash("No msg")
            return nil
        }
        return ReplyAllPossibleChecker(messageToReplyTo: message)
    }
    //
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

