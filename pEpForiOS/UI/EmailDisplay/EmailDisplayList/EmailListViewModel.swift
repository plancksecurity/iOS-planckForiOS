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

protocol EmailListViewModelProtocol: EmailDisplayViewModelProtocol {
    var folderName: String { get }
    func isEditable(messageAt indexPath: IndexPath) -> Bool
    func isSelectable(messageAt indexPath: IndexPath) -> Bool
    func viewModel(for index: Int) -> MessageViewModel?
    func shouldShowToolbarEditButtons() -> Bool
}

protocol EmailListViewModelDelegate: EmailDisplayViewModelDelegate {
    //BUFF: All moved to EmailDisplayViewModelDelegate. Will be filled with list specific stuff soon. Stay tuned!

    func setToolbarItemsEnabledState(to newValue: Bool)
    func showUnflagButton(enabled: Bool)
    func showUnreadButton(enabled: Bool)
}

// MARK: - EmailListViewModel

class EmailListViewModel: EmailDisplayViewModel, EmailListViewModelProtocol {
    private var emailDetailViewModel: EmailDetailViewModel?
    let contactImageTool = IdentityImageTool()
    //    var messageQueryResults: MessageQueryResults
    //
    //    var indexPathShown: IndexPath?
    //
    var lastSearchTerm = ""
    var updatesEnabled = true
    //
    //    weak var delegate: EmailListViewModelDelegate?
    //
    //    let folderToShow: DisplayableFolderProtocol
    //
    // MARK: - Filter

    public var isFilterEnabled = false {
        didSet {
            if oldValue != isFilterEnabled {
                handleFilterEnabledStateChange()
            }
        }
    }

    private var _currentFilter: MessageQueryResultsFilter?
    public private(set) var currentFilter: MessageQueryResultsFilter {
        get {
            if let cf = _currentFilter {
                return cf
            } else {
                return folderToShow.defaultFilter
            }
        }
        set {
            _currentFilter = newValue
        }
    }

    ////    public var screenComposer: ScreenComposerProtocol? //Commented out as the Message Thread feature has to be rewritten
    //
    //    private var selectedItems: Set<IndexPath>?
    //
    //    // Threading feature is currently non-existing. Keep this code, might help later.
    ////    weak var updateThreadListDelegate: UpdateThreadListDelegate?
    ////    var oldThreadSetting : Bool
    //
    //    // MARK: - Life Cycle
    //
    init(messageQueryResults: MessageQueryResults? = nil,
         delegate: EmailDisplayViewModelDelegate? = nil,
         folderToShow: DisplayableFolderProtocol) {
        super.init(messageQueryResults: messageQueryResults, folderToShow: folderToShow)
        self.messageQueryResults.rowDelegate = self
    }

    // MARK: - EmailListViewModelProtocol

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

    func viewModel(for index: Int) -> MessageViewModel? {
        let messageViewModel = MessageViewModel(with: messageQueryResults[index])
        return messageViewModel
    }

    func shouldShowToolbarEditButtons() -> Bool {
        switch folderToShow {
        case is VirtualFolderProtocol:
            return true
        case let folder as Folder:
            return folder.folderType != .outbox && folder.folderType != .drafts
        default:
            return true
        }
    }

    //BUFF: move ^^?

    //BUFF: move
    public var emailDetailViewIsAlreadyShown: Bool {
        return emailDetailViewModel != nil
    }

    // Forwards selection to EmailDetailView. Can be used to avoid re-instantiating of
    // EmailDetailView on every selection. Not sure if this is a good idea, smells like
    // needless optimization. Remove if it causes trouble. In this case also remove
    //`emailDetailViewIsAlreadyShown` and it's usage.
    public func handleSelected(itemAt indexPath: IndexPath) {
        emailDetailViewModel?.select(itemAt: indexPath)
    }

    public func shouldShowTutorialWizard() -> Bool {
        return AppSettings.shared.shouldShowTutorialWizard
    }

    func didShowTutorialWizard() {
        AppSettings.shared.shouldShowTutorialWizard = false
    }

    public func getDestructiveActtion(forMessageAt index: Int) -> SwipeActionDescriptor {
        let parentFolder = getParentFolder(forMessageAt: index)
        let defaultDestructiveAction: SwipeActionDescriptor
            = parentFolder.defaultDestructiveActionIsArchive
                ? .archive
                : .trash

        return folderIsOutbox(parentFolder) ? .trash : defaultDestructiveAction
    }

    public func getFlagAction(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftOrOutbox(parentFolder) {
            return nil
        } else {
            let flagged = messageQueryResults[index].imapFlags.flagged
            return flagged ? .unflag : .flag
        }
    }


    public func getMoreAction(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftOrOutbox(parentFolder) {
            return nil
        } else {
            return .more
        }
    }

    public var showLoginView: Bool {
        return Account.all().isEmpty
    }

    public func unreadFilterEnabled() -> Bool {
        guard let unread = currentFilter.mustBeUnread else {
            return false
        }
        return isFilterEnabled && unread
    }

    override func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])
        -> MoveToAccountViewModel? {
            let messages = messagesToMove(indexPaths: forSelectedMessages)
            if let msgs = messages as? [Message] {
                return MoveToAccountViewModel(messages: msgs)
            }
            return nil
    }

    // MARK: - Fetch Older Messages

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

    // Implemented to get informed about the currently visible cells.
    // If the user has scrolled down (almost) to the end, we ask for older emails.

    /// Get informed about the new visible cells.
    /// If the user has scrolled down (almost) to the end, we ask for older emails.
    ///
    /// - Parameter indexPath: indexpath to check need for fetch older for
    public func fetchOlderMessagesIfRequired(forIndexPath indexPath: IndexPath) {
        if !triggerFetchOlder(lastDisplayedRow: indexPath.row) {
            return
        }
        folderToShow.fetchOlder(completion: nil)
    }

    //MARK: - FetchNewMessages

    public func fetchNewMessages(completition: (() -> Void)? = nil) {
        folderToShow.fetchNewMessages() {
            completition?()
        }
    }

    //multiple message selection handler

    private var unreadMessages = false
    private var flaggedMessages = false

    public func updatedItems(indexPaths: [IndexPath]) {
        checkUnreadMessages(indexPaths: indexPaths)
        checkFlaggedMessages(indexPaths: indexPaths)
        guard let delegate = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("No delegate")
            return
        }
        if indexPaths.count > 0 {
            delegate.setToolbarItemsEnabledState(to: true)
        } else {
            delegate.setToolbarItemsEnabledState(to: false)
        }
    }

    private func checkFlaggedMessages(indexPaths: [IndexPath]) {
        let flagged = indexPaths.filter { (ip) -> Bool in
            if let flag = viewModel(for: ip.row)?.isFlagged {
                return flag
            }
            return false
        }

        guard let delegate = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("No delegate")
            return
        }
        if flagged.count == indexPaths.count {
            delegate.showUnflagButton(enabled: true)
        } else {
            delegate.showUnflagButton(enabled: false)
        }
    }

    private func checkUnreadMessages(indexPaths: [IndexPath]) {
        let read = indexPaths.filter { (ip) -> Bool in
            if let read = viewModel(for: ip.row)?.isSeen {
                return read
            }
            return false
        }

        guard let delegate = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("No delegate")
            return
        }
        if read.count == indexPaths.count {
            delegate.showUnreadButton(enabled: true)
        } else {
            delegate.showUnreadButton(enabled: false)
        }
    }

    public func markSelectedAsFlagged(indexPaths: [IndexPath]) {
        setFlagged(forIndexPath: indexPaths)
    }

    public func markSelectedAsUnFlagged(indexPaths: [IndexPath]) {
        unsetFlagged(forIndexPath: indexPaths)
    }

    public func markSelectedAsRead(indexPaths: [IndexPath]) {
        markRead(forIndexPath: indexPaths)
    }

    public func markSelectedAsUnread(indexPaths: [IndexPath]) {
        markUnread(forIndexPath: indexPaths)
    }

    public func deleteSelected(indexPaths: [IndexPath]) {
        let messages = indexPaths.map { messageQueryResults[$0.row] }
        delete(messages: messages)
    }

    public func messagesToMove(indexPaths: [IndexPath]) -> [Message?] {
        var messages : [Message?] = []
        indexPaths.forEach { (ip) in
            messages.append(self.message(representedByRowAt: ip))
        }
        return messages
    }
}

// MARK: - Filter & Search

extension EmailListViewModel {

    private func handleFilterEnabledStateChange() {
        if isFilterEnabled {
            setNewFilterAndReload(filter: currentFilter)
        } else {
            setNewFilterAndReload(filter: nil)
        }
    }

    public func setSearch(forSearchText txt: String) {
        if txt == lastSearchTerm {
            // Happens e.g. when initially setting the cursor in search bar.
            return
        }
        lastSearchTerm = txt

        let search = txt == "" ? nil : MessageQueryResultsSearch(searchTerm: lastSearchTerm)
        setNewSearchAndReload(search: search)
    }

    public func removeSearch() {
        setNewSearchAndReload(search: nil)
    }

    private func setNewSearchAndReload(search: MessageQueryResultsSearch?) {
        resetQueryResultsAndReload(with: messageQueryResults.filter, search: search)
    }

    private func setNewFilterAndReload(filter: MessageQueryResultsFilter?) {
        if let newFilter = filter {
            currentFilter = newFilter
        }
        resetQueryResultsAndReload(with: filter, search: messageQueryResults.search)
    }

    // Every time filter or search changes, we have to rest QueryResults
    private func resetQueryResultsAndReload(with filter: MessageQueryResultsFilter? = nil,
                                            search: MessageQueryResultsSearch? = nil) {
        defer { informDelegateToReloadData() }
        messageQueryResults = MessageQueryResults(withFolder: folderToShow,
                                                  filter: filter,
                                                  search: search,
                                                  rowDelegate: self)
        do {
            try messageQueryResults.startMonitoring()
            try emailDetailViewModel?.replaceMessageQueryResults(with: messageQueryResults)
        } catch {
            Log.shared.errorAndCrash("Failed to start QRC   ")
            return
        }
    }
}
// MARK: - Private

extension EmailListViewModel {

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
    //BUFF: move
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

    func freeMemory() {
        contactImageTool.clearCache()
    }
}

// MARK: - ComposeViewModel

extension EmailListViewModel {

    func composeViewModelForNewMessage() -> ComposeViewModel {
        // Determine the sender.
        var someUser: Identity? = nil
        if let f = folderToShow as? RealFolderProtocol {
            someUser = f.account.user
        } else {
            let account = Account.defaultAccount()
            return ComposeViewModel(resultDelegate:self, composeMode: .normal,
                                    prefilledFrom: account?.user)
        }
        let composeVM = ComposeViewModel(resultDelegate: self,
                                         prefilledFrom: someUser)
        return composeVM
    }
}

// MARK: - FilterViewDelegate

extension EmailListViewModel: FilterViewDelegate {
    public func filterChanged(newFilter: MessageQueryResultsFilter) {
        setNewFilterAndReload(filter: newFilter)
    }
}

//

extension EmailListViewModel {

    func emailDetialViewModel() -> EmailDetailViewModel {
        let detailQueryResults = messageQueryResults.clone()
        let createe = EmailDetailViewModel(messageQueryResults: detailQueryResults,
                                           folderToShow: folderToShow)
        createe.selectionChangeDelegate = self
        detailQueryResults.rowDelegate = createe
        emailDetailViewModel = createe

        return createe
    }
}

// MARK: - QueryResultsIndexPathRowDelegate //BUFF: make MessageQueryResultsIndexPathRowDelegate

extension EmailListViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        if updatesEnabled {
            delegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
        }
    }

    func didUpdateRow(indexPath: IndexPath) {
        if updatesEnabled {
            delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
        }
    }

    func didDeleteRow(indexPath: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        if updatesEnabled {
            delegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
        }
    }

    func willChangeResults() {
        if updatesEnabled {
            delegate?.willReceiveUpdates(viewModel: self)
        }
    }

    func didChangeResults() {
        if updatesEnabled {
            delegate?.allUpdatesReceived(viewModel: self)
        } else {
            updatesEnabled = true
        }
    }
}

extension EmailListViewModel {

    func isReplyAllPossible(forRowAt indexPath: IndexPath) -> Bool {
        guard
            let replyAllPossible = replyAllPossibleChecker(forItemAt: indexPath)?.isReplyAllPossible()
            else {
                Log.shared.errorAndCrash("Invalid state")
                return false
        }
        return replyAllPossible
    }
}

// MARK: - EmailDetailViewModelSelectionChangeDelegate

extension EmailListViewModel: EmailDetailViewModelSelectionChangeDelegate {

    func emailDetailViewModel(emailDetailViewModel: EmailDetailViewModel,
                              didSelectItemAt indexPath: IndexPath) {
        delegate?.select(itemAt: indexPath)
    }
}
