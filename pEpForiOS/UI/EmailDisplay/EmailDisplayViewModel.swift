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

protocol EmailDisplayViewModelDelegate: class, TableViewUpdate {
    //BUFF: rename delegate methods when working
    func emailListViewModel(viewModel: EmailDisplayViewModel, didInsertDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel, didUpdateDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didChangeSeenStateForDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel, didRemoveDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath)
    func checkIfSplitNeedsUpdate(indexpath: [IndexPath]) //BUFF: obsolete?
    /*
     //!!!: Some issues here: @Xavier
     - bad naming.
     - what is viewModel as the param
     - let's discuss & change!
     */
    func willReceiveUpdates(viewModel: EmailDisplayViewModel)
    func allUpdatesReceived(viewModel: EmailDisplayViewModel)
    func reloadData(viewModel: EmailDisplayViewModel)

    func toolbarIs(enabled: Bool)
    func showUnflagButton(enabled: Bool)
    func showUnreadButton(enabled: Bool)
}

// MARK: - EmailDisplayViewModel

/// Base class for MessageQueryResults driven email display view models.
class EmailDisplayViewModel {
    let contactImageTool = IdentityImageTool()
    var messageQueryResults: MessageQueryResults

    var indexPathShown: IndexPath?

    var lastSearchTerm = ""
    var updatesEnabled = true

    weak var delegate: EmailDisplayViewModelDelegate? //BUFF: rm var

    let folderToShow: DisplayableFolderProtocol
    private var selectedItems: Set<IndexPath>?

    // MARK: - Life Cycle

    init(delegate: EmailDisplayViewModelDelegate? = nil,
         folderToShow: DisplayableFolderProtocol) {
        self.delegate = delegate
        self.folderToShow = folderToShow

        // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
        messageQueryResults = MessageQueryResults(withFolder: folderToShow,
                                                  filter: nil,
                                                  search: nil)
        messageQueryResults.rowDelegate = self
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

    func setFlagged(forIndexPath indexPath: [IndexPath]) {
        setFlaggedValue(forIndexPath: indexPath, newValue: true)
    }

    func unsetFlagged(forIndexPath indexPath: [IndexPath]) {
        setFlaggedValue(forIndexPath: indexPath, newValue: false)
    }

    func markRead(forIndexPath indexPath: [IndexPath]) {
        setSeenValue(forIndexPath: indexPath, newValue: true)
    }

    func markUnread(forIndexPath indexPath: [IndexPath]) {
        setSeenValue(forIndexPath: indexPath, newValue: false)
    }

    func delete(forIndexPath indexPath: IndexPath) {
        deleteMessages(at: [indexPath])
    }

    func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messageQueryResults[indexPath.row]
    }

    func freeMemory() {
        contactImageTool.clearCache()
    }

    public func informDelegateToReloadData() {
        delegate?.reloadData(viewModel: self)
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
}

// MARK: - Private

extension EmailDisplayViewModel {

    private func setFlaggedValue(forIndexPath indexPath: [IndexPath], newValue flagged: Bool) {
        updatesEnabled = false
        let messages = indexPath.map { messageQueryResults[$0.row] }
        Message.setFlaggedValue(to: messages, newValue: flagged)
    }

    private func setSeenValue(forIndexPath indexPath: [IndexPath], newValue seen: Bool) {
        let messages = indexPath.map { messageQueryResults[$0.row] }
        Message.setSeenValue(to: messages, newValue: seen)
    }

    @discardableResult private func deleteMessages(at indexPath: [IndexPath]) -> [Message]? {
        let messages = indexPath.map { messageQueryResults[$0.row] }
        delete(messages: messages)
        return messages
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

// MARK: - ReplyAllPossibleCheckerProtocol

extension EmailDisplayViewModel: ReplyAllPossibleCheckerProtocol {
    func isReplyAllPossible(forMessage: Message?) -> Bool {
        return ReplyAllPossibleChecker().isReplyAllPossible(forMessage: forMessage)
    }

    func isReplyAllPossible(forRowAt indexPath: IndexPath) -> Bool {
        return isReplyAllPossible(forMessage: message(representedByRowAt: indexPath))
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

