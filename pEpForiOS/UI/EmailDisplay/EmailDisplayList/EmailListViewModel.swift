//
//  EmailListViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox
import MessageModel

protocol EmailListViewModelDelegate: EmailDisplayViewModelDelegate {
    func setToolbarItemsEnabledState(to newValue: Bool)
    func showUnflagButton(enabled: Bool)
    func showUnreadButton(enabled: Bool)
    func showEmail(forCellAt: IndexPath)
    func showEditDraftInComposeView()
    func select(itemAt indexPath: IndexPath)
    func deselect(itemAt indexPath: IndexPath)
    func finishEditingMode()
}

// MARK: - EmailListViewModel

class EmailListViewModel: EmailDisplayViewModel {

    private var emailDetailViewModel: EmailDetailViewModel?
    private var lastSearchTerm = ""
    private var updatesEnabled = true

    public var filterButtonTitle: String {
        var txt = currentFilter.getFilterText()
        if txt.count > filterMaxChars {
            let prefix = txt.prefix(ofLength: filterMaxChars)
            txt = String(prefix)
            txt += "..."
        }
        if txt.isEmpty {
            txt = NSLocalizedString("none", comment: "empty mail filter (no filter at all)")
        }
        let format = NSLocalizedString("Filter by: %@",
                                       comment: "'Filter by' in formatted string, followed by the localized filter name")
        let title = String(format: format, txt)
        return title

    }
    public let filterMaxChars = 20

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

    /// The email address of the account that contains the folder.
    ///
    /// If it's Unified folder, returns nil.
    public var emailAddress: String? {
        get {
            if let folder = folderToShow as? Folder {
                return folder.account.user.address
            }
            return nil
        }
    }
    
    private var account: Account? {
        get {
            if let folder = folderToShow as? Folder {
                return folder.account
            }
            return nil
        }
    }


    public let folderToShow: DisplayableFolderProtocol

    public var folderName: String {
        return Folder.localizedName(realName: folderToShow.title)
    }

    /// This is used to handle the selection row when it receives an update
    /// and also when swipeCellAction is performed to store from which cell the action is done.
    public var lastSelectedIndexPath: IndexPath?

    public var isDraftsPreviewMode: Bool {
        return folderToShow is UnifiedDraft
    }

    /// - Parameter indexPath: indexPath to check editability for.
    /// - returns:  Whether or not to show compose view rather then the email for message
    ///             represented by row at given `indexPath`.
    public func isEditable(messageAt indexPath: IndexPath) -> Bool {
        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .drafts {
            return true
        } else {
            return false
        }
    }

    public func isSelectable(messageAt indexPath: IndexPath) -> Bool {
        // Validate that indexPath.row is valid, return false if not.
        do {
            let resultCount = try messageQueryResults.count()
            if indexPath.row >= resultCount {
                Log.shared.errorAndCrash(message: "indexPath.row (\(indexPath.row)) out of bounds (\(resultCount)")
                return false
            }
        } catch {
            Log.shared.errorAndCrash(error: error)
            return false
        }

        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .outbox {
            return false
        } else {
            return true
        }
    }

    /// - Parameter indexPath: indexPath to get viewModel for
    /// - returns: ViewModel to configure Cell with
    public func viewModel(for index: Int) -> MessageViewModel? {
        let messageViewModel = MessageViewModel(with: messageQueryResults[index])
        return messageViewModel
    }

    /// Whether or not mails in the current folder are editable
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

    /// Whether or not the refresh control should be shown
    public var shouldShowRefreshController: Bool {
        if let unifiedFolder = folderToShow as? UnifiedFolderBase, let folderType = unifiedFolder.agregatedFolderType {
            return !folderType.isLocalFolder
        } else if let folder = folderToShow as? Folder {
            return !folder.folderType.isLocalFolder
        }
        return false
    }

    /// Returns the descriptor for the destructive action, it could be archive or trash
    /// - Parameter index: The index of the row
    /// - Returns: The descriptor to trigger the action if user taps a destructive button
    public func getDestructiveDescriptor(forMessageAt index: Int) -> SwipeActionDescriptor {
        let parentFolder = getParentFolder(forMessageAt: index)
        let defaultDestructiveAction: SwipeActionDescriptor
            = parentFolder.defaultDestructiveActionIsArchive
                ? .archive
                : .trash
        return folderIsOutbox(parentFolder) ? .trash : defaultDestructiveAction
    }

    /// Returns the descriptor with the Flag status (May be flag or unflag)
    /// - Parameter index: The index of the row
    /// - Returns: The descriptor to trigger the action if user taps "flag" button
    public func getFlagDescriptor(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftsOrOutbox(parentFolder) {
            return nil
        } else {
            let flagged = messageQueryResults[index].imapFlags.flagged
            return flagged ? .unflag : .flag
        }
    }

    /// Returns the descriptor with the Read status (May be read or unread)
    /// - Parameter index: The index of the row
    /// - Returns: The descriptor to trigger the action if user taps "read" button
    public func getReadDescriptor(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftsOrOutbox(parentFolder) {
            return nil
        }
        let seen = messageQueryResults[index].imapFlags.seen
        return seen ? .unread : .read
    }
    
    /// Returns the descriptor for the option More
    /// - Parameter index: The index of the row
    /// - Returns: The descriptor to trigger the action if user taps "More" button
    public func getMoreDescriptor(forMessageAt index: Int) -> SwipeActionDescriptor? {
        let parentFolder = getParentFolder(forMessageAt: index)
        if folderIsDraftsOrOutbox(parentFolder) {
            return nil
        } else {
            return .more
        }
    }

    /// Whether or not to show LoginView
    public var showLoginView: Bool {
        return Account.all().isEmpty
    }

    public func isReplyAllPossible(forRowAt indexPath: IndexPath) -> Bool {
        guard
            let replyAllPossible = replyAllPossibleChecker(forItemAt: indexPath)?.isReplyAllPossible() else {
                Log.shared.errorAndCrash("Invalid state")
                return false
        }
        return replyAllPossible
    }

    /// Marks the message represented by the given `indexPaths` as flagged.
    /// - Parameter indexPaths: indexPaths of messages to set flagged.
    /// - Parameter isEditModeEnabled: Indicates if edit mode is enabled
    public func markAsFlagged(indexPaths: [IndexPath], isEditModeEnabled: Bool) {
        self.updatesEnabled = isEditModeEnabled
        setFlaggedValue(forIndexPath: indexPaths, newValue: true)
        self.updatesEnabled = true
    }

    /// Marks the message represented by the given `indexPaths` as not-flagged.
    /// - Parameter indexPaths: indexPaths of messages to unsset flag flag for.
    /// - Parameter isEditModeEnabled: Indicates if edit mode is enabled
    public func markAsUnFlagged(indexPaths: [IndexPath], isEditModeEnabled: Bool) {
        self.updatesEnabled = isEditModeEnabled
        setFlaggedValue(forIndexPath: indexPaths, newValue: false)
        self.updatesEnabled = true
    }

    /// Marks the message represented by the given `indexPaths` as seen.
    /// - Parameter indexPaths: indexPaths of messages to set seen.
    /// - Parameter isEditModeEnabled: Indicates if edit mode is enabled
    public func markAsRead(indexPaths: [IndexPath], isEditModeEnabled: Bool) {
        self.updatesEnabled = isEditModeEnabled
        setSeenValue(forIndexPath: indexPaths, newValue: true)
        self.updatesEnabled = true
    }

    /// Marks the message represented by the given `indexPaths` as not-seen.
    /// - Parameter indexPaths: indexPaths of messages to unsset seen flag for.
    /// - Parameter isEditModeEnabled: Indicates if edit mode is enabled
    public func markAsUnread(indexPaths: [IndexPath], isEditModeEnabled: Bool) {
        self.updatesEnabled = isEditModeEnabled
        setSeenValue(forIndexPath: indexPaths, newValue: false)
        self.updatesEnabled = true
    }

    /// Handles destructive button click for messages represented by given `indexPaths`.
    /// - Parameter indexPath: indexPathsdo handle destruktive action for
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

     /// Call in case of out-of-memory alert
    func freeMemory() {
        IdentityImageTool.clearCache()
    }

    /// Update LastLookAt of the folder to show.
    public func updateLastLookAt() {
        folderToShow.updateLastLookAt()
    }

    public func handleBannerIfNeeded() {
        if !NetworkMonitorUtil.shared.netOn {
            UIUtils.showNoInternetConnectionBanner()
        } else {
            UIUtils.hideBanner()
        }
    }

    public func moveMailsToSuspiciousIfPossible() {
        guard folderName != Folder.planckSuspiciousFolderName else {
            // Nothing to process in the suspicious folder
            return
        }
        // Move the dangerous messages to the suspicious folder if possible.
        let suspiciousMessages = messageQueryResults.all.filter { SuspiciousMessageUtil.shouldMoveToSuspiciousFolder(message: $0) }

        guard let account = account else {
            Log.shared.errorAndCrash("Account not found.")
            return
        }
        guard let folder = Folder.getSuspiciousFolder(account: account) else {
            Log.shared.errorAndCrash("Suspicious folder not found.")
            return
        }
        if !suspiciousMessages.isEmpty {
            Message.move(messages: suspiciousMessages, to: folder)
        }
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

    // When the user has scrolled down (almost) to the end, we fetch older emails.
    /// - Parameter indexPath: indexpath to pontetionally fetch older messages for
    public func fetchOlderMessagesIfRequired(forIndexPath indexPath: IndexPath) {
        if !triggerFetchOlder(lastDisplayedRow: indexPath.row) {
            return
        }
        folderToShow.fetchOlder(completion: nil)
    }

    // MARK: - FetchNewMessages

    public func fetchNewMessages(completition: (() -> Void)? = nil) {
        folderToShow.fetchNewMessages() {
            DispatchQueue.main.async {
                completition?()
            }
        }
    }

    // MARK: - Multiple message selection handler

    /// Handles changes of the selected messages in edit mode.
    /// Updates toolbar buttons (maybe more)  accoring to selection.
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

    /// Handles did select row action and make a decision what to do next (show different view or something else)
    public func handleDidSelectRow(indexPath: IndexPath) {
        guard let del = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("Wrong Delegate")
            return
        }

        if isSelectable(messageAt: indexPath) {
            lastSelectedIndexPath = indexPath
            del.select(itemAt: indexPath)
            if isEditable(messageAt: indexPath) {
                del.showEditDraftInComposeView()
            } else {
                del.showEmail(forCellAt: indexPath)
                markUIOnlyAsSeen(indexPath: indexPath)
            }
        } else {
            del.deselect(itemAt: indexPath)
        }
    }

    private func markUIOnlyAsSeen(indexPath: IndexPath) {
        let message = messageQueryResults[indexPath.row]
        message.markUIOnlyAsSeen()
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

    /// Call whenever the term to search for changes.
    /// - Parameter newSearchTerm: updated search term
    public func handleSearchTermChange(newSearchTerm: String) {
        if newSearchTerm == lastSearchTerm {
            // Happens e.g. when initially setting the cursor in search bar.
            return
        }
        lastSearchTerm = newSearchTerm

        let search = newSearchTerm == "" ? nil : MessageQueryResultsSearch(searchTerm: lastSearchTerm)
        setNewSearchAndReload(search: search)
    }

    /// Handles dissapearance of a SearchController
    public func handleSearchControllerDidDisappear() {
        setNewSearchAndReload(search: nil)
    }

    private func handleFilterEnabledStateChange() {
        if isFilterEnabled {
            setNewFilterAndReload(filter: currentFilter)
        } else {
            setNewFilterAndReload(filter: nil)
        }
        mergeImapUIStateToImapState()
    }

    /// Merge the Imap UIState of emails To Imap State.
    /// This does not affect the UI.
    /// If there is no uistate to merge, nothing will happen.
    public func mergeImapUIStateToImapState() {
        // Create a new filter to get the emails that use uiflags.
        let uiMarkedFilter = MessageQueryResultsFilter(mustBeFlagged: currentFilter.mustBeFlagged,
                                                       mustBeUnread: currentFilter.mustBeUnread,
                                                       mustContainAttachments: currentFilter.mustContainAttachments,
                                                       mustHaveImapUIFlags: true,
                                                       accounts: currentFilter.accounts)

        // Create a new MessageQueryResults to not update the UI.
        // Delegate is nil as we don't want to react to any change here.
        let newMessageQueryResults = MessageQueryResults(withFolder: folderToShow,
                                                         filter: uiMarkedFilter,
                                                         search: messageQueryResults.search,
                                                         rowDelegate: nil)
        do {
            try newMessageQueryResults.startMonitoring()
            if try newMessageQueryResults.count() == 0 {
                return
            }
            // Merge the ui state into the IMAP state.
            Message.mergeUIState(messages: newMessageQueryResults.all)
        } catch {
            Log.shared.errorAndCrash("Failed to start QRC")
            return
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

    private func setFlaggedValue(forIndexPath indexPaths: [IndexPath], newValue flagged: Bool) {
        let messages = indexPaths.map { messageQueryResults[$0.row] }
        Message.setFlaggedValue(to: messages, newValue: flagged)
    }

    private func setSeenValue(forIndexPath indexPath: [IndexPath], newValue seen: Bool) {
        let messages = indexPath.map { messageQueryResults[$0.row] }
        Message.setSeenValue(to: messages, newValue: seen)
    }

    @discardableResult
    private func deleteMessages(at indexPaths: [IndexPath]) -> [Message]? {
        let messages = indexPaths.map { messageQueryResults[$0.row] }
        delete(messages: messages)
        return messages
    }

    private func finishEditingMode() {
        guard let delegate = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("No delegate")
            return
        }
        DispatchQueue.main.async {
            delegate.finishEditingMode()
        }
    }
}

// MARK: - Destination View Controller VM-Factory

extension EmailListViewModel {

    /// Destination View Controller's VM Factory
    /// - returns:  ComposeViewModel  with default configuration (for a new email).
    public func composeViewModelForNewMessage() -> ComposeViewModel {
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

    /// Destination VM Factory - EmailDetail VM
    /// - returns:  EmailDetailViewModel with default configuration.
    public func emailDetialViewModel() -> EmailDetailViewModel {
        let detailQueryResults = messageQueryResults.clone()
        let createe = EmailDetailViewModel(messageQueryResults: detailQueryResults)
        createe.currentFilter = currentFilter
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
            guard let del = delegate as? EmailListViewModelDelegate else {
                Log.shared.errorAndCrash("Wrong Delegate")
                return
            }
            del.finishEditingMode()
            del.allUpdatesReceived(viewModel: self)
        } else {
            updatesEnabled = true
        }
    }
}

// MARK: - EmailDetailViewModelSelectionChangeDelegate

extension EmailListViewModel: EmailDetailViewModelSelectionChangeDelegate {

    func emailDetailViewModel(emailDetailViewModel: EmailDetailViewModel,
                              didSelectItemAt indexPath: IndexPath) {
        guard let del = delegate as? EmailListViewModelDelegate else {
            Log.shared.errorAndCrash("Wrong Delegate")
            return
        }
        del.select(itemAt: indexPath)
    }
}

