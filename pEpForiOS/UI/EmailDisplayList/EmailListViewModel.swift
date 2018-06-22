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
    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPath: IndexPath)
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPath: IndexPath)
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPath: IndexPath)
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
    
    internal var messages: SortedSet<PreviewMessage>
    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInteractive
        return createe
    }()

    public var emailListViewModelDelegate: EmailListViewModelDelegate?

    internal let folderToShow: Folder
    internal let threadedMessageFolder: ThreadedMessageFolderProtocol

    public var currentDisplayedMessage: DisplayedMessage?

    let sortByDateSentAscending: SortedSet<PreviewMessage>.SortBlock =
    { (pvMsg1: PreviewMessage, pvMsg2: PreviewMessage) -> ComparisonResult in
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
    
    // MARK: - Life Cycle
    
    init(emailListViewModelDelegate: EmailListViewModelDelegate? = nil,
         messageSyncService: MessageSyncServiceProtocol,
         folderToShow: Folder) {
        self.messages = SortedSet(array: [], sortBlock: sortByDateSentAscending)
        self.emailListViewModelDelegate = emailListViewModelDelegate
        self.messageSyncService = messageSyncService

        self.folderToShow = folderToShow
        self.threadedMessageFolder = FolderThreading.makeThreadAware(folder: folderToShow)
        resetViewModel()
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
        queue.addOperation { [weak self] in
            if let theSelf = self {
                let messagesToDisplay = theSelf.folderToShow.allMessages()
                let previewMessages = messagesToDisplay.map {
                    PreviewMessage(withMessage: $0)
                }

                theSelf.messages = SortedSet(array: previewMessages,
                                          sortBlock: theSelf.sortByDateSentAscending)
                DispatchQueue.main.async {
                    theSelf.emailListViewModelDelegate?.updateView()
                    theSelf.startListeningToChanges()
                }
            }
        }
    }
    
    // MARK: - Public Data Access & Manipulation

    func index(of message: Message) -> Int? {
        return messages.index(of: PreviewMessage(withMessage: message))
    }
    
    func viewModel(for index: Int) -> MessageViewModel? {
        guard let message = messages.object(at: index)?.message() else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "InconsistencyviewModel vs. model")
            return nil
        }
        return MessageViewModel(with: message)
    }

    
    var rowCount: Int {
        return messages.count
    }
    
    /// Returns the senders contact image to display.
    /// This is a possibly time consuming process and shold not be called from the main thread.
    ///
    /// - Parameter indexPath: row indexpath to get the contact image for
    /// - Returns: contact image to display
    func senderImage(forCellAt indexPath:IndexPath) -> UIImage? {
        guard let previewMessage = messages.object(at: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "InconsistencyviewModel vs. model")
            return nil
        }
        return contactImageTool.identityImage(for: previewMessage.from)
    }
    
    private func cachedSenderImage(forCellAt indexPath:IndexPath) -> UIImage? {
        guard
            indexPath.row < messages.count,
            let previewMessage = messages.object(at: indexPath.row)
            else {
            // The model has been updated.
            return nil
        }
        return contactImageTool.cachedIdentityImage(forIdentity: previewMessage.from)
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
        indexPaths.forEach { (ip) in
            delete(forIndexPath: ip)

        }
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
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            previewMessage.isSeen = true
            me.emailListViewModelDelegate?.emailListViewModel(viewModel: me,
                                                                      didUpdateDataAt: indexPath)
        }
    }

    func markUnread(forIndexPath indexPath: IndexPath) {
        guard let previewMessage = messages.object(at: indexPath.row) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            previewMessage.isSeen = false
            me.emailListViewModelDelegate?.emailListViewModel(viewModel: me,
                                                                      didUpdateDataAt: indexPath)
        }
    }
    
    func delete(forIndexPath indexPath: IndexPath) {
        guard let previewMessage = messages.object(at: indexPath.row),
            let message = previewMessage.message() else {
                return
        }
        threadedMessageFolder.deleteThread(message: message)
        didDelete(messageFolder: message)

    }
    
    func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messages.object(at: indexPath.row)?.message()
    }
    
    func freeMemory() {
        contactImageTool.clearCache()
    }
    
    internal func setFlaggedValue(forIndexPath indexPath: IndexPath, newValue flagged: Bool) {
        guard let previewMessage = messages.object(at: indexPath.row),
            let message = previewMessage.message() else {
                return
        }
        message.imapFlags?.flagged = flagged
        didUpdate(messageFolder: message)
        DispatchQueue.main.async {
            message.save()
        }
    }

    public func reloadData() {
        resetViewModel()
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
            folderFilter.without(filters: filterViewFilter)
        }
        resetViewModel()
    }
    
    public func setSearchFilter(forSearchText txt: String = "") {
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
            Log.shared.errorAndCrash(component: #function, errorString: "No folder.")
            return
        }
        filter.removeSearchFilter()
        resetViewModel()
    }

    private func assuredFilterOfFolderToShow() -> CompositeFilter<FilterBase> {
        if folderToShow.filter == nil {
            folderToShow.resetFilter()
        }

        guard let folderFilter = folderToShow.filter else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We just set the filter but do not have one?")
            return CompositeFilter<FilterBase>.defaultFilter()
        }
        return folderFilter
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

    // MARK - Misc

    /**
     Is the detail view currently displaying messages derived from `Message`?
     */
    func currentlyDisplaying(message: Message) -> Bool {
        return currentDisplayedMessage?.messageModel == message
    }
}
