//
//  EmailListViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol EmailListViewModelDelegate: TableViewUpdate {
    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel,
                            didChangeSeenStateForDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath])
    func emailListViewModel(viewModel: EmailListViewModel,
                            didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath)
    func toolbarIs(enabled: Bool)
    func showUnflagButton(enabled: Bool)
    func showUnreadButton(enabled: Bool)
}

// MARK: - FilterUpdateProtocol

extension EmailListViewModel: FilterUpdateProtocol {
    public func addFilter(_ filter: CompositeFilter<FilterBase>) {
        setFilterViewFilter(filter: filter)
    }
}

// MARK: - EmailListViewModel

class EmailListViewModel {
    let messageFolderDelegateHandlingQueue = DispatchQueue(label:
        "net.pep-security-EmailListViewModel-MessageFolderDelegateHandling")
    let contactImageTool = IdentityImageTool()
    let messageSyncService: MessageSyncServiceProtocol
    internal var messages: SortedSet<MessageViewModel>
    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    var lastSearchTerm = ""

    public var emailListViewModelDelegate: EmailListViewModelDelegate?

    internal let folderToShow: Folder
    internal let threadedMessageFolder: ThreadedMessageFolderProtocol

    public var currentDisplayedMessage: DisplayedMessage?
    public var screenComposer: ScreenComposerProtocol?

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

    weak var updateThreadListDelegate: UpdateThreadListDelegate?
    var defaultFilter: CompositeFilter<FilterBase>?

    var oldThreadSetting : Bool
    
    // MARK: - Life Cycle
    
    init(emailListViewModelDelegate: EmailListViewModelDelegate? = nil,
         messageSyncService: MessageSyncServiceProtocol,
         folderToShow: Folder = UnifiedInbox()) {
        self.messages = SortedSet(array: [], sortBlock: sortByDateSentAscending)
        self.emailListViewModelDelegate = emailListViewModelDelegate
        self.messageSyncService = messageSyncService

        self.folderToShow = folderToShow
        self.threadedMessageFolder = FolderThreading.makeThreadAware(folder: folderToShow)
        self.defaultFilter = folderToShow.filter?.clone()
        self.oldThreadSetting = AppSettings.threadedViewEnabled
        
        resetViewModel()
        
    }

    func updateLastLookAt() {
        folderToShow.updateLastLookAt()
    }

    func getFolderName() -> String {
        return folderToShow.localizedName
    }

    func shouldEditMessage() -> Bool {
        if folderToShow.folderType == .drafts || folderToShow.folderType == .outbox {
            return true
        } else {
            return false
        }
    }
    
    //check if there are some important settings that have changed to force a reload
    func checkIfSettingsChanged() -> Bool {
        if AppSettings.threadedViewEnabled != oldThreadSetting {
            oldThreadSetting = AppSettings.threadedViewEnabled
            return true
        }
        return false
    }

    internal func startListeningToChanges() {
        MessageModelConfig.messageFolderDelegate = self
    }

    internal func stopListeningToChanges() {
        MessageModelConfig.messageFolderDelegate = nil
    }

    private func resetViewModel() {
        // Ignore MessageModelConfig.messageFolderDelegate while reloading.
        self.stopListeningToChanges()

        queue.cancelAllOperations()
        let op = BlockOperation()
        weak var weakOp = op
        op.addExecutionBlock { [weak self] in
            guard
                let me = self,
                let op = weakOp,
                !op.isCancelled else {
                return
            }
            let messagesToDisplay = me.folderToShow.allMessages()
            let previewMessages = messagesToDisplay.map {
                MessageViewModel(with: $0)
            }
            let sortedMessages = SortedSet(array: previewMessages, sortBlock: me.sortByDateSentAscending)
            if op.isCancelled {
                return
            }
            DispatchQueue.main.sync {
                me.messages = sortedMessages
                me.emailListViewModelDelegate?.updateView()
                me.startListeningToChanges()
            }
        }
        queue.addOperation(op)
    }

    // MARK: - Public Data Access & Manipulation

    func index(of message: Message) -> Int? {
        return messages.index(of: MessageViewModel(with: message))
    }

    func viewModel(for index: Int) -> MessageViewModel? {
        guard let messageViewModel = messages.object(at: index) else {
            Logger.frontendLogger.errorAndCrash("InconsistencyviewModel vs. model")
            return nil
        }
        return messageViewModel
    }

    var rowCount: Int {
        return messages.count
    }

    private func cachedSenderImage(forCellAt indexPath:IndexPath) -> UIImage? {
        guard
            indexPath.row < messages.count,
            let previewMessage = messages.object(at: indexPath.row)
            else {
            // The model has been updated.
            return nil
        }
        return contactImageTool.cachedIdentityImage(for: previewMessage.identity)
    }

    func pEpRatingColorImage(forCellAt indexPath: IndexPath) -> UIImage? {
        guard
            indexPath.row < messages.count,
            let previewMessage = messages.object(at: indexPath.row),
            let message = previewMessage.message()
            else {
                // The model has been updated.
                return nil
        }
        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating())
        if color != PEP_color_no_color {
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

    public func checkFlaggedMessages(indexPaths: [IndexPath]) {
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

    public func checkUnreadMessages(indexPaths: [IndexPath]) {
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
        var deletees = [MessageViewModel]()
        indexPaths.forEach { (ip) in
            guard let previewMessage = messages.object(at: ip.row)else {
                    return
            }
            deletees.append(previewMessage)
        }

        for pvm in deletees {
            guard let message = pvm.message() else {
                Logger.frontendLogger.errorAndCrash("No mesage")
                return
            }
            delete(message: message)
            messages.remove(object: pvm)
        }
        //emailListViewModelDelegate?.emailListViewModel(viewModel: self, didRemoveDataAt: indexPaths)
    }

    public func messagesToMove(indexPaths: [IndexPath]) -> [Message?] {
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
        guard let previewMessage = messages.object(at: indexPath.row) else {
            return
        }
        DispatchQueue.main.async { [] in
            previewMessage.isSeen = true
            let message = previewMessage.message()
            message?.imapFlags?.seen = true
            message?.save()
        }
    }

    func markUnread(forIndexPath indexPath: IndexPath) {
        guard let previewMessage = messages.object(at: indexPath.row) else {
            return
        }
        DispatchQueue.main.async { [] in
            previewMessage.isSeen = false
            let message = previewMessage.message()
            message?.imapFlags?.seen = false
            message?.save()
        }
    }

    func delete(forIndexPath indexPath: IndexPath) {
        guard let deletedMessage = deleteMessage(at: indexPath) else {
            Logger.frontendLogger.errorAndCrash(
                "Not sure if this is a valid case. Remove this log if so.")
            return
        }
        didDelete(messageFolder: deletedMessage, belongingToThread: Set())
    }

    private func deleteMessage(at indexPath: IndexPath) -> Message? {
        guard let previewMessage = messages.object(at: indexPath.row),
            let message = previewMessage.message() else {
                return nil
        }
        delete(message: message)
        return message
    }

    private func delete(message: Message) {
        // The message to delete might be a single, unthreaded message,
        // or the tip of a thread. `threadedMessageFolder` will figure it out.
        threadedMessageFolder.deleteThread(message: message)
    }

    func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messages.object(at: indexPath.row)?.message()
    }

    internal func requestEmailViewIfNeeded(for message:Message) {
        MessageModel.performAndWait {
            if (message.numberOfMessagesInThread() == 0) {
                DispatchQueue.main.async {
                    self.screenComposer?.emailListViewModel(self, requestsShowEmailViewFor: message)
                }
            }
        }
    }

    func freeMemory() {
        contactImageTool.clearCache()
    }
    
    internal func setFlaggedValue(forIndexPath indexPath: IndexPath, newValue flagged: Bool) {
        guard let previewMessage = messages.object(at: indexPath.row),
            let message = previewMessage.message() else {
                return
        }
        previewMessage.isFlagged = flagged
        message.imapFlags?.flagged = flagged
        DispatchQueue.main.async {
            message.save()
        }
    }

    public func reloadData() {
        resetViewModel()
    }

    public func shouldShowToolbarEditButtons() -> Bool {
        return !folderIsOutbox(folderToShow)
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
            let flagged = messages.object(at: index)?.message()?.imapFlags?.flagged ?? false
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

    public func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }

    public func folderIsDraft() -> Bool {
        return folderIsDraft( folderToShow)
    }

    public func folderIsOutbox() -> Bool {
        return folderIsOutbox(folderToShow)
    }

    public func unreadFilterEnabled() -> Bool {
        return isFilterEnabled &&
            activeFilter?.contains(type: UnreadFilter.self) ?? false
    }

    private func getParentFolder(forMessageAt index: Int) -> Folder {
        var parentFolder: Folder

        if folderToShow is UnifiedInbox {
            // folderToShow is unified inbox, fetch parent folder from DB.
            guard let folder = messages.object(at: index)?.message()?.parent else {
                    Logger.frontendLogger.errorAndCrash("Dangling Message")
                    return folderToShow
            }
            parentFolder = folder
        } else {
            // Do not bother our imperformant MessageModel if we already know the parent folder
            // folderToShow is unified inbox, fetch parent folder from DB.
            parentFolder = folderToShow
        }

        return parentFolder
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

    public func getMoveToFolderViewModel(forSelectedMessages: [IndexPath])
        -> MoveToAccountViewModel? {
            let messages = messagesToMove(indexPaths: forSelectedMessages)
            if let msgs = messages as? [Message] {
                return MoveToAccountViewModel(messages: msgs)
            }
            return nil
    }

    //TODO: remove when Segues of EmailListViewController are refactored.
    public func getFolderToShow() -> Folder {
        return folderToShow
    }

    //TODO: remove when Segues of EmailListViewController are refactored.
    public func getFolderIsUnified() -> Bool {
        return folderToShow is UnifiedInbox
    }

    //TODO: remove when Segues of EmailListViewController are refactored.
    public func getFolderFilters() -> CompositeFilter<FilterBase>? {
        return folderToShow.filter
    }

    // MARK: - Filter
    
    public var isFilterEnabled = false {
        didSet {
            handleFilterEnabledSwitch()
        }
    }
    public var activeFilter : CompositeFilter<FilterBase>? {
        return folderToShow.filter
    }

    static let defaultFilterViewFilter = CompositeFilter<FilterBase>.defaultFilter()
    private var _filterViewFilter: CompositeFilter = defaultFilterViewFilter
    private var filterViewFilter: CompositeFilter<FilterBase> {
        get {
            if _filterViewFilter.isEmpty() {
                _filterViewFilter = EmailListViewModel.defaultFilterViewFilter
            }
            return _filterViewFilter
        }
        set {
            _filterViewFilter = newValue
        }
    }

    private func setFilterViewFilter(filter: CompositeFilter<FilterBase>) {
        if isFilterEnabled {
            let folderFilter = assuredFilterOfFolderToShow()
            folderFilter.without(filters: filterViewFilter)
            folderFilter.with(filters: filter)
            resetViewModel()
        }
        filterViewFilter = filter
    }

    private func handleFilterEnabledSwitch() {
        let folderFilter = assuredFilterOfFolderToShow()
        if isFilterEnabled {
            folderFilter.with(filters: filterViewFilter)
        } else {
            self.folderToShow.filter = defaultFilter?.clone()
        }
        resetViewModel()
    }

    public func setSearchFilter(forSearchText txt: String = "") {
        if txt == lastSearchTerm {
            // Happens e.g. when initially setting the cursor in search bar.
            return
        }
        lastSearchTerm = txt
        if txt == "" {
            assuredFilterOfFolderToShow().removeSearchFilter()
        } else {
            let folderFilter = assuredFilterOfFolderToShow()
            folderFilter.removeSearchFilter()
            let searchFilter = SearchFilter(searchTerm: txt)
            folderFilter.add(filter: searchFilter)
        }
        resetViewModel()
    }

    public func removeSearchFilter() {
        guard let filter = folderToShow.filter else {
            Logger.frontendLogger.errorAndCrash("No folder.")
            return
        }
        let filtersChanged = filter.removeSearchFilter()
        if filtersChanged {
            resetViewModel()
        }
    }

    private func assuredFilterOfFolderToShow() -> CompositeFilter<FilterBase> {
        if folderToShow.filter == nil {
            folderToShow.resetFilter()
        }

        guard let folderFilter = folderToShow.filter else {
            Logger.frontendLogger.errorAndCrash("We just set the filter but do not have one?")
            return CompositeFilter<FilterBase>.defaultFilter()
        }
        return folderFilter
    }

    // MARK: - Util

    func folderIsDraft(_ parentFolder: Folder?) -> Bool {
        guard let folder = parentFolder else {
            Logger.frontendLogger.errorAndCrash("No parent.")
            return false
        }
        return folder.folderType == .drafts
    }

    func folderIsOutbox(_ parentFolder: Folder?) -> Bool {
        guard let folder = parentFolder else {
            Logger.frontendLogger.errorAndCrash("No parent.")
            return false
        }
        return folder.folderType == .outbox
    }

    func folderIsDraftsOrOutbox(_ parentFolder: Folder?) -> Bool {
        return folderIsDraft(parentFolder) || folderIsOutbox(parentFolder)
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
        if let unifiedFolder = folderToShow as? UnifiedInbox {
            requestFetchOlder(forFolders: unifiedFolder.folders)
        } else {
            requestFetchOlder(forFolders: [folderToShow])
        }
    }

    private func requestFetchOlder(forFolders folders: [Folder]) {
        DispatchQueue.main.async { [weak self] in
            for folder in folders {
                self?.messageSyncService.requestFetchOlderMessages(inFolder: folder)
            }
        }
    }
}

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
        let message = messages.object(at: indexPath.row)?.message()
        let composeVM = ComposeViewModel(resultDelegate: self,
                                         composeMode: composeMode,
                                         originalMessage: message)
        return composeVM
    }

    func composeViewModelForNewMessage() -> ComposeViewModel {
        let user = folderToShow.account.user
        let composeVM = ComposeViewModel(resultDelegate: self,
                                         prefilledFrom: user)
        return composeVM
    }
}

// MARK: - ComposeViewModelResultDelegate

extension EmailListViewModel: ComposeViewModelResultDelegate {
    func composeViewModelDidComposeNewMail() {
        if folderIsDraftsOrOutbox(folderToShow){
            // In outbox, a new mail must show up after composing it.
            reloadData()
        }
    }

    func composeViewModelDidDeleteMessage() {
        if folderIsDraftOrOutbox(folderToShow) {
            // A message from outbox has been deleted in outbox
            // (e.g. because the user saved it to drafts).
            reloadData()
        }
    }

    func composeViewModelDidModifyMessage() {
        if folderIsDraft(folderToShow) {
            reloadData()
        }
    }
}
