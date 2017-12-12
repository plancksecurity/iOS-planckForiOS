//
//  EmailListViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol EmailListViewModelDelegate: class {
    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPath: IndexPath)
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPath: IndexPath)
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPath: IndexPath)
    func emailListViewModelPrapareForResetData(viewModel: EmailListViewModel,
                                               readyForReset: ()->Void)
    func emailListViewModelDidResetData(viewModel: EmailListViewModel)
}

// MARK: - FilterUpdateProtocol

extension EmailListViewModel: FilterUpdateProtocol {
    public func addFilter(_ filter: CompositeFilter<FilterBase>) {
        setFilterViewFilter(filter: filter)
    }
}

// MARK: - EmailListViewModel

class EmailListViewModel {
    fileprivate let messageFolderDelegateHandlingQueue = DispatchQueue(label:
        "net.pep-security-EmailListViewModel-MessageFolderDelegateHandling")
    private let contactImageTool = IdentityImageTool()
    private let messageSyncService: MessageSyncServiceProtocol
    class Row {
        var senderContactImage: UIImage?
        var ratingImage: UIImage?
        var showAttchmentIcon: Bool = false
        let from: String
        let to: String
        let subject: String
        let bodyPeek: String
        var isFlagged: Bool = false
        var isSeen: Bool = false
        var dateText: String
        
        init(withPreviewMessage pvmsg: PreviewMessage, senderContactImage: UIImage? = nil) {
            self.senderContactImage = senderContactImage
            showAttchmentIcon = pvmsg.hasAttachments
            from = pvmsg.from.userNameOrAddress
            to = pvmsg.to
            subject = pvmsg.subject
            bodyPeek = pvmsg.bodyPeek
            isFlagged = pvmsg.isFlagged
            isSeen = pvmsg.isSeen
            dateText = pvmsg.dateSent.smartString()
        }
    }
    
    private var messages: SortedSet<PreviewMessage>?
    private var folderToShow: Folder?
    private let sortByDateSentAscending: SortedSet<PreviewMessage>.SortBlock =
    { (pvMsg1: PreviewMessage, pvMsg2: PreviewMessage) -> ComparisonResult in
        if pvMsg1.dateSent > pvMsg2.dateSent {
            return .orderedAscending
        } else if pvMsg1.dateSent < pvMsg2.dateSent {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    public weak var delegate: EmailListViewModelDelegate?
    public private(set) var isLoading = false
    
    // MARK: Life Cycle
    
    init(delegate: EmailListViewModelDelegate? = nil, messageSyncService: MessageSyncServiceProtocol,
         folderToShow: Folder? = nil) {
        self.messages = SortedSet(array: [], sortBlock: sortByDateSentAscending)
        self.delegate = delegate
        self.messageSyncService = messageSyncService
        self.folderToShow = folderToShow
        resetViewModel()
    }

    private func startListeningToChanges() {
        MessageModelConfig.messageFolderDelegate = self
    }

    private func stopListeningToChanges() {
        MessageModelConfig.messageFolderDelegate = nil
    }
    
    private func resetViewModel() {
        guard let folder = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data, no cry.")
            return
        }
        guard !isLoading else {
            return
        }
        // Ignore MessageModelConfig.messageFolderDelegate while reloading data.
        self.stopListeningToChanges()
        isLoading = true
        delegate?.emailListViewModelPrapareForResetData(viewModel: self) {
            let messagesToDisplay = folder.allMessages()
            let previewMessages = messagesToDisplay.map { PreviewMessage(withMessage: $0) }

            self.messages = SortedSet(array: previewMessages,
                                      sortBlock: self.sortByDateSentAscending)
            DispatchQueue.main.async {
                self.isLoading = false
                self.delegate?.emailListViewModelDidResetData(viewModel: self)
                self.startListeningToChanges()
            }
        }
    }
    
    // MARK: Internal
    
    private func indexOfPreviewMessage(forMessage msg:Message) -> Int? {
        guard let previewMessages = messages else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data.")
            return nil
        }
        for i in 0..<previewMessages.count {
            guard let pvMsg = previewMessages.object(at: i) else {
                Log.shared.errorAndCrash(component: #function, errorString: "Inconsistant data")
                return nil
            }
            if pvMsg == msg {
                return i
            }
        }
        return nil
    }
    
    // MARK: Public Data Access & Manipulation
    
    func row(for indexPath: IndexPath) -> Row? {
        guard let previewMessage = messages?.object(at: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "InconsistencyviewModel vs. model")
            return nil
        }
        if let cachedSenderImage = contactImageTool.cachedIdentityImage(forIdentity: previewMessage.from) {
            return Row(withPreviewMessage: previewMessage, senderContactImage: cachedSenderImage)
        } else {
            return Row(withPreviewMessage: previewMessage)
        }
    }
    
    var rowCount: Int {
        return messages?.count ?? 0
    }
    
    /// Returns the senders contact image to display.
    /// This is a possibly time consuming process and shold not be called from the main thread.
    ///
    /// - Parameter indexPath: row indexpath to get the contact image for
    /// - Returns: contact image to display
    func senderImage(forCellAt indexPath:IndexPath) -> UIImage? {
        guard let previewMessage = messages?.object(at: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "InconsistencyviewModel vs. model")
            return nil
        }
        return contactImageTool.identityImage(for: previewMessage.from)
    }
    
    private func cachedSenderImage(forCellAt indexPath:IndexPath) -> UIImage? {
        guard let previewMessage = messages?.object(at: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "InconsistencyviewModel vs. model")
            return nil
        }
        return contactImageTool.cachedIdentityImage(forIdentity: previewMessage.from)
    }
    
    func pEpRatingColorImage(forCellAt indexPath: IndexPath) -> UIImage? {
        guard let previewMessage = messages?.object(at: indexPath.row),
            let message = previewMessage.message() else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "InconsistencyviewModel vs. model")
                return nil
        }
        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating())
        let result = color.statusIcon()
        return result
    }
    
    func setFlagged(forIndexPath indexPath: IndexPath) {
        setFlagged(forIndexPath: indexPath, newValue: true)
    }
    
    func unsetFlagged(forIndexPath indexPath: IndexPath) {
        setFlagged(forIndexPath: indexPath, newValue: false)
    }
    
    func markRead(forIndexPath indexPath: IndexPath) {
        guard let previewMessage = messages?.object(at: indexPath.row) else {
            return
        }
        previewMessage.isSeen = true
        delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: indexPath)
    }
    
    func delete(forIndexPath indexPath: IndexPath) {
        guard let previewMessage = messages?.object(at: indexPath.row),
            let message = previewMessage.message() else {
                return
        }
        messages?.remove(object: previewMessage)
        message.imapDelete()
    }
    
    func message(representedByRowAt indexPath: IndexPath) -> Message? {
        return messages?.object(at: indexPath.row)?.message()
    }
    
    func freeMemory() {
        contactImageTool.clearCache()
    }
    
    private func setFlagged(forIndexPath indexPath: IndexPath, newValue flagged: Bool) {
        guard let previewMessage = messages?.object(at: indexPath.row),
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

    // MARK: Filter
    
    public var isFilterEnabled = false {
        didSet {
            handleFilterEnabledSwitch()
        }
    }
    public var activeFilter : CompositeFilter<FilterBase>? {
        get {
            guard let folder = folderToShow else {
                return nil
            }
            return folder.filter
        }
    }

    static let defaultFilterViewFilter = CompositeFilter<FilterBase>.DefaultFilter()
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
            folderFilter.With(filters: filter)
            resetViewModel()
        }
        filterViewFilter = filter
    }

    private func handleFilterEnabledSwitch() {
        let folderFilter = assuredFilterOfFolderToShow()
        if isFilterEnabled {
            folderFilter.With(filters: filterViewFilter)
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
            let searchFilter = SearchFilter(subject: txt)
            folderFilter.add(filter: searchFilter)
        }
        resetViewModel()
    }
    
    public func removeSearchFilter() {
        guard let filter = folderToShow?.filter else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder.")
            return
        }
        filter.removeSearchFilter()
        resetViewModel()
    }

    private func assuredFilterOfFolderToShow() -> CompositeFilter<FilterBase> {
        guard let folder = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder.")
            return CompositeFilter<FilterBase>.DefaultFilter()
        }
        if folder.filter == nil{
            folder.resetFilter()
        }

        guard let folderFilter = folder.filter else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We just set the filter but do not have one?")
            return CompositeFilter<FilterBase>.DefaultFilter()
        }
        return folderFilter
    }

    // MARK: - Fetch Older Messages

    /// The number of rows (not yet displayed to the user) before we want to fetch older messages.
    /// A balance between good user experience (have data in time, ideally before the user has scrolled
    /// to the last row) and memory usage has to be found.
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
        guard let folder = folderToShow else {
            return
        }
        if !triggerFetchOlder(lastDisplayedRow: indexPath.row) {
            return
        }
        if folder is UnifiedInbox {
            guard let unified = folder as? UnifiedInbox else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error casting")
                return
            }
            requestFetchOlder(forFolders: unified.folders)
        } else {
            requestFetchOlder(forFolders: [folder])
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

// MARK: - MessageFolderDelegate

extension EmailListViewModel: MessageFolderDelegate {

    func didCreate(messageFolder: MessageFolder) {
        messageFolderDelegateHandlingQueue.async {
            self.didCreateInternal(messageFolder: messageFolder)
        }
    }
    
    func didUpdate(messageFolder: MessageFolder) {
        messageFolderDelegateHandlingQueue.async {
            self.didUpdateInternal(messageFolder: messageFolder)
        }
    }
    
    func didDelete(messageFolder: MessageFolder) {
        messageFolderDelegateHandlingQueue.async {
            self.didDeleteInternal(messageFolder: messageFolder)
        }
    }
    
    private func didCreateInternal(messageFolder: MessageFolder) {
        guard let message = messageFolder as? Message else {
            // The createe is no message. Ignore.
            return
        }
        if !shouldBeDisplayed(message: message){
            return
        }
        // Is a Message (not a Folder)
        if let filter = folderToShow?.filter,
            !filter.fulfilsFilter(message: message) {
            // The message does not fit in current filter criteria. Ignore- and do not show it.
            return
        }
        let previewMessage = PreviewMessage(withMessage: message)
        guard let index = messages?.insert(object: previewMessage) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should be able to insert.")
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        DispatchQueue.main.async {
            self.delegate?.emailListViewModel(viewModel: self, didInsertDataAt: indexPath)
        }
    }
    
    private func didDeleteInternal(messageFolder: MessageFolder) {
        // Make sure it is a Message (not a Folder). Flag must have changed
        guard let message = messageFolder as? Message else {
            // It is not a Message (probably it is a Folder).
            return
        }
        if !shouldBeDisplayed(message: message){
            return
        }
        // Is a Message (not a Folder)
        guard let indexExisting = indexOfPreviewMessage(forMessage: message) else {
            // We do not have this message in our model, so we do not have to remove it
            return
        }
        guard let pvMsgs = messages else {
            Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
            return
        }
        pvMsgs.removeObject(at: indexExisting)
        let indexPath = IndexPath(row: indexExisting, section: 0)
        DispatchQueue.main.async {
            self.delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: indexPath)
        }
    }
    
    private func didUpdateInternal(messageFolder: MessageFolder) {
        // Make sure it is a Message (not a Folder). Flag must have changed
        guard let message = messageFolder as? Message else {
            // It is not a Message (probably it is a Folder).
            return
        }
        if !shouldBeDisplayed(message: message){
            return
        }
        guard let pvMsgs = messages else {
            Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
            return
        }

        if indexOfPreviewMessage(forMessage: message) == nil {
            // We do not have this updated message in our model yet. It might have been updated in a way,
            // that fulfills the current filters now but did not before the update.
            // Or it has just been decrypted.
            // Forward to didCreateInternal to figure out if we want to display it.
            self.didCreateInternal(messageFolder: messageFolder)
            return
        }

        // We do have this message in our model, so we do have to update it
        guard let indexExisting = indexOfPreviewMessage(forMessage: message),
            let existingMessage = pvMsgs.object(at: indexExisting) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "We should have the message at this point")
                return
        }

        let previewMessage = PreviewMessage(withMessage: message)
        if !previewMessage.flagsDiffer(previewMessage: existingMessage) {
            // The only message properties displayed in this view that might be updated are flagged and seen.
            // We got called even the flaggs did not change. Ignore.
            return
        }
        
        let indexToRemove = pvMsgs.index(of: existingMessage)
        pvMsgs.removeObject(at: indexToRemove)

        if let filter = folderToShow?.filter,
            !filter.fulfilsFilter(message: message) {
            // The message was included in the model, but does not fulfil the filter criteria
            // anymore after it has been updated.
            // Remove it.
            let indexPath = IndexPath(row: indexToRemove, section: 0)
            DispatchQueue.main.async {
                self.delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: indexPath)
            }
            return
        }
        // The updated message has to be shown. Add it to the model ...
        let indexInserted = pvMsgs.insert(object: previewMessage)
        if indexToRemove != indexInserted  {Log.shared.warn(component: #function,
                                                            content:
            """
When updating a message, the the new index of the message must be the same as the old index.
Something is fishy here.
"""
            )
        }
        // ...  and inform the delegate.
        let indexPath = IndexPath(row: indexInserted, section: 0)
        DispatchQueue.main.async {
            self.delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: indexPath)
        }
    }

    private func shouldBeDisplayed(message: Message) -> Bool {
        if !isInFolderToShow(message: message) {
            return false
        }
        if message.isEncrypted {
            return false
        }
        return true
    }

    private func isInFolderToShow(message: Message) -> Bool {
        if folderToShow is UnifiedInbox {
            if message.parent.folderType == .inbox {
                return true
            }
        } else {
            return message.parent == folderToShow
        }
        return false
    }
}
