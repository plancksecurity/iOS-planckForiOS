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

protocol EmailListViewModelDelegate: TableViewUpdate {
    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel,
                            didChangeSeenStateForDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel,
                            didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath)
    func willReceiveUpdates(viewModel: EmailListViewModel)
    func allUpdatesReceived(viewModel: EmailListViewModel)
    func reloadData(viewModel: EmailListViewModel)
    func toolbarIs(enabled: Bool)
    func showUnflagButton(enabled: Bool)
    func showUnreadButton(enabled: Bool)
}

// MARK: - FilterViewDelegate

extension EmailListViewModel: FilterViewDelegate {
    public func filterChanged(newFilter: MessageQueryResultsFilter) {
        setNewFilterAndReload(filter: newFilter)
    }
}

// MARK: - EmailListViewModel

class EmailListViewModel {
    let contactImageTool = IdentityImageTool()
    var messageQueryResults: MessageQueryResults

    var indexPathShown: IndexPath?

    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    var lastSearchTerm = ""
    var updatesEnabled = true

    public var emailListViewModelDelegate: EmailListViewModelDelegate?

    let folderToShow: DisplayableFolderProtocol

    public var currentDisplayedMessage: DisplayedMessage?

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
                return MessageQueryResultsFilter(
                    mustBeUnread: false,
                    accountEnabledStates: folderToShow.defaultFilter.accountsEnabledStates)
            }
        }
        set {
            _currentFilter = newValue
        }
    }

//    public var screenComposer: ScreenComposerProtocol? //Commented out as the Message Thread feature has to be rewritten

    let sortByDateSentAscending: SortedSet<MessageViewModel>.SortBlock =
    { (pvMsg1: MessageViewModel, pvMsg2: MessageViewModel) -> ComparisonResult in
        if pvMsg1.dateSent > pvMsg2.dateSent {
            return .orderedAscending
        } else if pvMsg1.dateSent < pvMsg2.dateSent {
            return .orderedDescending
        } else if pvMsg1.uid > pvMsg2.uid {
            return .orderedAscending
        } else if pvMsg1.uid < pvMsg2.uid {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    private var selectedItems: Set<IndexPath>?

    weak var updateThreadListDelegate: UpdateThreadListDelegate? //!!!: sounds like belonging to message thread. If so, comment out

    // Threading feature is currently non-existing. Keep this code, might help later.
//    var oldThreadSetting : Bool

    // MARK: - Life Cycle

    init(emailListViewModelDelegate: EmailListViewModelDelegate? = nil,
         folderToShow: DisplayableFolderProtocol) {
        self.emailListViewModelDelegate = emailListViewModelDelegate
        self.folderToShow = folderToShow

        // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
        messageQueryResults = MessageQueryResults(withFolder: folderToShow,
                                                       filter: folderToShow.defaultFilter,
                                                       search: nil)
        messageQueryResults.delegate = self
        // Threading feature is currently non-existing. Keep this code, might help later.
//        self.oldThreadSetting = AppSettings.threadedViewEnabled
    }

    func startMonitoring() {
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Logger.frontendLogger.errorAndCrash("MessageQueryResult crash")
        }
    }

    var folderName: String {
        return Folder.localizedName(realName: folderToShow.title)
    }

    func shouldEditMessage(indexPath: IndexPath) -> Bool {
        let message = messageQueryResults[indexPath.row]
        if message.parent.folderType == .drafts || message.parent.folderType == .outbox {
            return true
        } else {
            return false
        }
    }

    // Threading feature is currently non-existing. Keep this code, might help later.
//    //check if there are some important settings that have changed to force a reload
//    func checkIfSettingsChanged() -> Bool {
//        if AppSettings.threadedViewEnabled != oldThreadSetting {
//            oldThreadSetting = AppSettings.threadedViewEnabled
//            return true
//        }
//        return false
//    }

    // MARK: - Public Data Access & Manipulation

    func index(of message: Message) -> Int? {
        return nil
    }

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
        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating())
        if color != PEPColor.noColor {
            return color.statusIcon()
        } else {
            return nil
        }
    }

    //multiple message selection handler

    private var unreadMessages = false
    private var flaggedMessages = false

    public func updatedItems(indexPaths: [IndexPath]) {
        checkUnreadMessages(indexPaths: indexPaths)
        checkFlaggedMessages(indexPaths: indexPaths)
        if indexPaths.count > 0 {
            emailListViewModelDelegate?.toolbarIs(enabled: true)
        } else {
            emailListViewModelDelegate?.toolbarIs(enabled: false)
        }
    }

    private func checkFlaggedMessages(indexPaths: [IndexPath]) {
        let flagged = indexPaths.filter { (ip) -> Bool in
            if let flag = viewModel(for: ip.row)?.isFlagged {
                return flag
            }
            return false
        }

        if flagged.count == indexPaths.count {
            emailListViewModelDelegate?.showUnflagButton(enabled: true)
        } else {
            emailListViewModelDelegate?.showUnflagButton(enabled: false)
        }
    }

    private func checkUnreadMessages(indexPaths: [IndexPath]) {
        let read = indexPaths.filter { (ip) -> Bool in
            if let read = viewModel(for: ip.row)?.isSeen {
                return read
            }
            return false
        }

        if read.count == indexPaths.count {
            emailListViewModelDelegate?.showUnreadButton(enabled: true)
        } else {
            emailListViewModelDelegate?.showUnreadButton(enabled: false)
        }
    }

    public func markSelectedAsFlagged(indexPaths: [IndexPath]) {
        indexPaths.forEach { (ip) in
            setFlagged(forIndexPath: ip)
        }
    }

    public func markSelectedAsUnFlagged(indexPaths: [IndexPath]) {
        indexPaths.forEach { (ip) in
            unsetFlagged(forIndexPath: ip)
        }
    }

    public func markSelectedAsRead(indexPaths: [IndexPath]) {
        indexPaths.forEach { (ip) in
            markRead(forIndexPath: ip)
        }
    }

    public func markSelectedAsUnread(indexPaths: [IndexPath]) {
        indexPaths.forEach { (ip) in
            markUnread(forIndexPath: ip)
        }
    }

    public func deleteSelected(indexPaths: [IndexPath]) {
        updatesEnabled = false
        indexPaths.forEach { (ip) in
            let message = messageQueryResults[ip.row]
            delete(message: message)
        }
    }

    public func messagesToMove(indexPaths: [IndexPath]) -> [Message?] {
        updatesEnabled = false
        var messages : [Message?] = []
        indexPaths.forEach { (ip) in
            messages.append(self.message(representedByRowAt: ip))
        }
        return messages
    }
    
    func setFlagged(forIndexPath indexPath: IndexPath) {
        setFlaggedValue(forIndexPath: indexPath, newValue: true)
    }

    func unsetFlagged(forIndexPath indexPath: IndexPath) {
        setFlaggedValue(forIndexPath: indexPath, newValue: false)
    }
    
    func markRead(forIndexPath indexPath: IndexPath) {
        updatesEnabled = false
        let message = messageQueryResults[indexPath.row]
        DispatchQueue.main.async { [] in
            message.imapFlags.seen = true
            message.save()
        }
    }

    func markUnread(forIndexPath indexPath: IndexPath) {
        updatesEnabled = false
        let message = messageQueryResults[indexPath.row]
        DispatchQueue.main.async { [] in
            message.imapFlags.seen = false
            message.save()
        }
    }

    func delete(forIndexPath indexPath: IndexPath) {
        guard let deletedMessage = deleteMessage(at: indexPath) else {
            Logger.frontendLogger.errorAndCrash(
                "Not sure if this is a valid case. Remove this log if so.")
            return
        }
    }

    func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messageQueryResults[indexPath.row]
    }

    //
//    internal func requestEmailViewIfNeeded(for message:Message) {
//        MessageModelUtil.performAndWait {
//            DispatchQueue.main.async {
//                self.screenComposer?.emailListViewModel(self, requestsShowEmailViewFor: message)
//            }
//        }
//    }

    func freeMemory() {
        contactImageTool.clearCache()
    }

    public func informDelegateToReloadData() {
        emailListViewModelDelegate?.reloadData(viewModel: self)
    }

    public func shouldShowToolbarEditButtons() -> Bool {
        if folderToShow is VirtualFolderProtocol {
            return true
        } else if let f = folderToShow as? Folder {
            return !(f.folderType == .outbox)
        }
        return true
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
            let flagged = messageQueryResults[index].imapFlags.flagged ?? false
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

    public func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])
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
        folderToShow.fetchOlder()
    }

    private func requestFetchOlder(forFolders folders: [Folder]) {
        DispatchQueue.main.async {
            for folder in folders {
                folder.fetchOlder()
            }
        }
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
                                                  delegate: self)
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Logger.modelLogger.errorAndCrash("Failed to fetch data")
            return
        }
    }
}
// MARK: - Private

extension EmailListViewModel {

    private func setFlaggedValue(forIndexPath indexPath: IndexPath, newValue flagged: Bool) {
        updatesEnabled = false
        let message = messageQueryResults[indexPath.row]
        message.imapFlags.flagged = flagged
        DispatchQueue.main.async {
            message.save()
        }
    }

    private func deleteMessage(at indexPath: IndexPath) -> Message? {
        let message = messageQueryResults[indexPath.row]
        delete(message: message)
        return message
    }

    private func delete(message: Message) {
        message.imapDelete()
    }

    private func cachedSenderImage(forCellAt indexPath:IndexPath) -> UIImage? {

        guard let count = try? messageQueryResults.count(), indexPath.row < count else {
            // The model has been updated or it's not ready to use.
            return nil
        }
        let message = messageQueryResults[indexPath.row]
        guard let from = message.from else {
            return nil
        }
        return contactImageTool.cachedIdentityImage(for: from)
    }
}

// MARK: - ReplyAllPossibleCheckerProtocol

extension EmailListViewModel: ReplyAllPossibleCheckerProtocol {
    func isReplyAllPossible(forMessage: Message?) -> Bool {
        return ReplyAllPossibleChecker().isReplyAllPossible(forMessage: forMessage)
    }

    func isReplyAllPossible(forRowAt indexPath: IndexPath) -> Bool {
        return isReplyAllPossible(forMessage: message(representedByRowAt: indexPath))
    }
}

// MARK: - ComposeViewModel

extension EmailListViewModel {
    func composeViewModel(withOriginalMessageAt indexPath: IndexPath,
                          composeMode: ComposeUtil.ComposeMode? = nil) -> ComposeViewModel {
        let message = messageQueryResults[indexPath.row]
        let composeVM = ComposeViewModel(resultDelegate: self,
                                         composeMode: composeMode,
                                         originalMessage: message)
        return composeVM
    }

    func composeViewModelForNewMessage() -> ComposeViewModel {
        if let f = folderToShow as? RealFolder {
            return ComposeViewModel(resultDelegate:self, composeMode: .normal,
                                    prefilledFrom: f.account.user)
        } else {
            let account = Account.defaultAccount()
            return ComposeViewModel(resultDelegate:self, composeMode: .normal,
                                    prefilledFrom: account?.user)

        }
    }
}

// MARK: - ComposeViewModelResultDelegate

extension EmailListViewModel: ComposeViewModelResultDelegate {
    func composeViewModelDidComposeNewMail(message: Message) {
        if folderIsDraftsOrOutbox(message.parent){
            informDelegateToReloadData()
        }
    }

    func composeViewModelDidDeleteMessage(message: Message) {
        if folderIsDraftOrOutbox(message.parent) {
            informDelegateToReloadData()
        }
    }

    func composeViewModelDidModifyMessage(message: Message) {
        if folderIsDraft(message.parent){
            informDelegateToReloadData()
        }
    }
}

// MARK: - FolderType Utils

extension EmailListViewModel {

    private func getParentFolder(forMessageAt index: Int) -> Folder {
        return messageQueryResults[index].parent
    }

    private func folderIsOutbox(_ parentFolder: Folder) -> Bool {
        return parentFolder.folderType == .outbox
    }

    private func folderIsDraft(_ parentFolder: Folder) -> Bool {
        return parentFolder.folderType == .drafts
    }

    private func folderIsDraftOrOutbox(_ parentFoldder: Folder) -> Bool {
        return folderIsDraft(parentFoldder) || folderIsOutbox(parentFoldder)
    }

    private func folderIsDraft(_ parentFolder: Folder?) -> Bool {
        guard let folder = parentFolder else {
            Logger.frontendLogger.errorAndCrash("No parent.")
            return false
        }
        return folderIsDraft(folder)
    }

    private func folderIsOutbox(_ parentFolder: Folder?) -> Bool {
        guard let folder = parentFolder else {
            Logger.frontendLogger.errorAndCrash("No parent.")
            return false
        }
        return folderIsOutbox(folder)
    }

    private func folderIsDraftsOrOutbox(_ parentFolder: Folder?) -> Bool {
        return folderIsDraft(parentFolder) || folderIsOutbox(parentFolder)
    }
}
