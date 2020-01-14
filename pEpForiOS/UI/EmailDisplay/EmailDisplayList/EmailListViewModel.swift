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
    var folderToShow: DisplayableFolderProtocol { get }

    var isFilterEnabled: Bool { get set }
    var currentFilter: MessageQueryResultsFilter { get }

    /// - Parameter indexPath: indexPath to check editability for.
    /// - returns: Whether or not to show compose view rather then the email for message represented by row at given `indexPath`.
    func isEditable(messageAt indexPath: IndexPath) -> Bool

    /// - Parameter indexPath: indexPath to check selectability for.
    /// - returns: Whether or not the message represented by row at given `indexPath` is selecdtable in the current state.
    func isSelectable(messageAt indexPath: IndexPath) -> Bool
    /// - Parameter indexPath: indexPath to get viewModel for
    /// - returns: ViewModel to configure Cell with
    func viewModel(for index: Int) -> MessageViewModel?

    /// Whether or not mails in the current folder are editable
    var shouldShowToolbarEditButtons: Bool { get }

    /// Used for UI fine tuning: Do not instatiate a EmailDetailVC if there is one already to avoid
    /// minor gliches while longer HTML body is loaded.
    var emailDetailViewIsAlreadyShown: Bool { get }

    // Forwards selection to EmailDetailView. Can be used to avoid re-instantiating of
    // EmailDetailView on every selection. Not sure if this is a good idea, smells like
    // needless optimization. Remove if it causes trouble. In this case also remove
    //`emailDetailViewIsAlreadyShown` and it's usage.
    func handleSelected(itemAt indexPath: IndexPath)

    /// Whether or not to show the Tutorial
    var shouldShowTutorialWizard: Bool { get }
    /// Call when the tutorial has been displayed to the user
    func didShowTutorialWizard()

    /// - returns: action to trigger if user clicks destructive button
    func getDestructiveAction(forMessageAt index: Int) -> SwipeActionDescriptor
    /// - returns: action to trigger if user clicks "flag" button
    func getFlagAction(forMessageAt index: Int) -> SwipeActionDescriptor?
    /// - returns: action to trigger if user clicks "more" button
    func getMoreAction(forMessageAt index: Int) -> SwipeActionDescriptor?

    /// Whether or not to show LoginView
    var showLoginView: Bool { get }

    func isReplyAllPossible(forRowAt indexPath: IndexPath) -> Bool

    /// Marks the message represented by the given `indexPaths` as flagged.
    /// - Parameter indexPath: indexPaths of messages to set flagged.
    func markAsFlagged(indexPaths: [IndexPath])
    /// Marks the message represented by the given `indexPaths` as not-flagged.
    /// - Parameter indexPath: indexPaths of messages to unsset flag flag for.
    func markAsUnFlagged(indexPaths: [IndexPath])
    /// Marks the message represented by the given `indexPaths` as seen.
    /// - Parameter indexPath: indexPaths of messages to set seen.
    func markAsRead(indexPaths: [IndexPath])
    /// Marks the message represented by the given `indexPaths` as not-seen.
    /// - Parameter indexPath: indexPaths of messages to unsset seen flag for.
    func markAsUnread(indexPaths: [IndexPath])
    /// Handles destructive button click for messages represented by given `indexPaths`.
    /// - Parameter indexPath: indexPathsdo handle destruktive action for
    func handleUserClickedDestruktiveButton(forRowsAt indexPaths: [IndexPath])

    func delete(forIndexPath indexPath: IndexPath)

    /// Call in case of out-of-memory alert
    func freeMemory()

    // If the user has scrolled down (almost) to the end, we fetch older emails.
    /// - Parameter indexPath: indexpath to pontetionally fetch older messages for
    func fetchOlderMessagesIfRequired(forIndexPath indexPath: IndexPath)
    func fetchNewMessages(completition: (() -> Void)?)

    /// Handles changes of the selected messages in edit mode.
    /// Updates toolbar buttons (maybe more)  accoring to selection.
    func handleEditModeSelectionChange(selectedIndexPaths: [IndexPath])

    /// Call whenever the term to search for changes.
    /// - Parameter newSearchTerm: updated search term
    func handleSearchTermChange(newSearchTerm: String)

    /// Handles dissapearance of a SearchController
    func handleSearchControllerDidDisappear()

    /// Destination View Controller's VM Factory
    /// - returns:  ComposeViewModel  with default configuration (for a new email).
    func composeViewModelForNewMessage() -> ComposeViewModel

    /// Destination VM Factory - EmailDetail VM
    /// - returns:  EmailDetailViewModel with default configuration.
    func emailDetialViewModel() -> EmailDetailViewModelProtocol
}

protocol EmailListViewModelDelegate: EmailDisplayViewModelDelegate {
    func setToolbarItemsEnabledState(to newValue: Bool)
    func showUnflagButton(enabled: Bool)
    func showUnreadButton(enabled: Bool)
}

// MARK: - EmailListViewModel

class EmailListViewModel: EmailDisplayViewModel, EmailListViewModelProtocol {
    private var emailDetailViewModel: EmailDetailViewModelProtocol?
    private let contactImageTool = IdentityImageTool()

    private var lastSearchTerm = ""
    private var updatesEnabled = true

    // MARK: - Life Cycle

    init(delegate: EmailListViewModelDelegate? = nil, folderToShow: DisplayableFolderProtocol) {
        self.folderToShow = folderToShow
        let messageQueryResults = MessageQueryResults(withFolder: folderToShow,
                                                      filter: nil,
                                                      search: nil)
        super.init(delegate: delegate, messageQueryResults: messageQueryResults)
        self.messageQueryResults.rowDelegate = self
    }

    // MARK: - EmailListViewModelProtocol

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

    public var isFilterEnabled = false {
        didSet {
            if oldValue != isFilterEnabled {
                handleFilterEnabledStateChange()
            }
        }
    }

    public let folderToShow: DisplayableFolderProtocol

    public var folderName: String {
        return Folder.localizedName(realName: folderToShow.title)
    }

    public func isEditable(messageAt indexPath: IndexPath) -> Bool {
        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .drafts {
            return true
        } else {
            return false
        }
    }

    public func isSelectable(messageAt indexPath: IndexPath) -> Bool {
        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .outbox {
            return false
        } else {
            return true
        }
    }

    public func viewModel(for index: Int) -> MessageViewModel? {
        let messageViewModel = MessageViewModel(with: messageQueryResults[index])
        return messageViewModel
    }

    public var shouldShowToolbarEditButtons: Bool {
        switch folderToShow {
        case is VirtualFolderProtocol:
            return true
        case let folder as Folder:
            return folder.folderType != .outbox && folder.folderType != .drafts
        default:
            return true
        }
    }

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

    public var shouldShowTutorialWizard: Bool {
        return AppSettings.shared.shouldShowTutorialWizard
    }

    public func didShowTutorialWizard() {
        AppSettings.shared.shouldShowTutorialWizard = false
    }

    public func getDestructiveAction(forMessageAt index: Int) -> SwipeActionDescriptor {
        let parentFolder = getParentFolder(forMessageAt: index)
        let defaultDestructiveAction: SwipeActionDescriptor
            = parentFolder.defaultDestructiveActionIsArchive
                ? .archive
                : .trash

        return folderIsOutbox(parentFolder) ? .trash : defaultDestructiveAction
    }

    public func getFlagAction(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftsOrOutbox(parentFolder) {
            return nil
        } else {
            let flagged = messageQueryResults[index].imapFlags.flagged
            return flagged ? .unflag : .flag
        }
    }
    public func getMoreAction(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftsOrOutbox(parentFolder) {
            return nil
        } else {
            return .more
        }
    }

    public var showLoginView: Bool {
        return Account.all().isEmpty
    }

    public func isReplyAllPossible(forRowAt indexPath: IndexPath) -> Bool {
        guard
            let replyAllPossible = replyAllPossibleChecker(forItemAt: indexPath)?.isReplyAllPossible()
            else {
                Log.shared.errorAndCrash("Invalid state")
                return false
        }
        return replyAllPossible
    }

    public func markAsFlagged(indexPaths: [IndexPath]) {
        setFlaggedValue(forIndexPath: indexPaths, newValue: true)
    }

    public func markAsUnFlagged(indexPaths: [IndexPath]) {
        setFlaggedValue(forIndexPath: indexPaths, newValue: false)
    }

    public func markAsRead(indexPaths: [IndexPath]) {
        setSeenValue(forIndexPath: indexPaths, newValue: true)
    }

    public func markAsUnread(indexPaths: [IndexPath]) {
        setSeenValue(forIndexPath: indexPaths, newValue: false)
    }

    public func handleUserClickedDestruktiveButton(forRowsAt indexPaths: [IndexPath]) {
        let messages = indexPaths.map { messageQueryResults[$0.row] }
        delete(messages: messages)
    }

    private func messages(representedBy indexPaths: [IndexPath]) -> [Message?] {
        var messages : [Message?] = []
        indexPaths.forEach { (ip) in
            messages.append(self.message(representedByRowAt: ip))
        }
        return messages
    }

    func delete(forIndexPath indexPath: IndexPath) {
        deleteMessages(at: [indexPath])
    }

    func freeMemory() {
        contactImageTool.clearCache()
    }

    // MARK: - EmailDisplayViewModelDelegate Overrides

    override func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])
        -> MoveToAccountViewModel? {
            if let msgs = messages(representedBy: forSelectedMessages) as? [Message] {
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

    // MARK: - FetchNewMessages

    public func fetchNewMessages(completition: (() -> Void)? = nil) {
        folderToShow.fetchNewMessages() {
            completition?()
        }
    }

    // MARK: - multiple message selection handler

    private var unreadMessages = false
    private var flaggedMessages = false

    public func handleEditModeSelectionChange(selectedIndexPaths: [IndexPath]) {
        checkUnreadMessages(indexPaths: selectedIndexPaths)
        checkFlaggedMessages(indexPaths: selectedIndexPaths)
        guard let delegate = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("No delegate")
            return
        }
        if selectedIndexPaths.count > 0 {
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
}

// MARK: - Filter & Search

extension EmailListViewModel {

    public func handleSearchTermChange(newSearchTerm: String) {
        if newSearchTerm == lastSearchTerm {
            // Happens e.g. when initially setting the cursor in search bar.
            return
        }
        lastSearchTerm = newSearchTerm

        let search = newSearchTerm == "" ? nil : MessageQueryResultsSearch(searchTerm: lastSearchTerm)
        setNewSearchAndReload(search: search)
    }

    public func handleSearchControllerDidDisappear() {
        setNewSearchAndReload(search: nil)
    }

    private func handleFilterEnabledStateChange() {
        if isFilterEnabled {
            setNewFilterAndReload(filter: currentFilter)
        } else {
            setNewFilterAndReload(filter: nil)
        }
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
}

// MARK: - Destination View Controller VM-Factory

extension EmailListViewModel {

    func composeViewModelForNewMessage() -> ComposeViewModel {
        // Determine the sender.
        var someUser: Identity? = nil
        if let f = folderToShow as? RealFolderProtocol {
            someUser = f.account.user
        } else {
            let account = Account.defaultAccount()
            return ComposeViewModel(composeMode: .normal,
                                    prefilledFrom: account?.user)
        }
        let composeVM = ComposeViewModel(prefilledFrom: someUser)
        return composeVM
    }

    func emailDetialViewModel() -> EmailDetailViewModelProtocol {
        let detailQueryResults = messageQueryResults.clone()
        let createe = EmailDetailViewModel(messageQueryResults: detailQueryResults)
        createe.selectionChangeDelegate = self
        detailQueryResults.rowDelegate = createe
        emailDetailViewModel = createe

        return createe
    }
}

// MARK: - FilterViewDelegate

extension EmailListViewModel: FilterViewDelegate {

    func filterChanged(newFilter: MessageQueryResultsFilter) {
        setNewFilterAndReload(filter: newFilter)
    }
}

// MARK: - QueryResultsIndexPathRowDelegate

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

// MARK: - EmailDetailViewModelSelectionChangeDelegate

extension EmailListViewModel: EmailDetailViewModelSelectionChangeDelegate {

    func emailDetailViewModel(emailDetailViewModel: EmailDetailViewModelProtocol,
                              didSelectItemAt indexPath: IndexPath) {
        delegate?.select(itemAt: indexPath)
    }
}
