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
}

// MARK: - FilterUpdateProtocol

extension EmailListViewModel: FilterUpdateProtocol {
    public func addFilter(_ filter: Filter) {
        setFilterViewFilter(filter: filter)
    }
}

// MARK: - EmailListViewModel

class EmailListViewModel {
    let contactImageTool = IdentityImageTool()
    class Row {
        var senderContactImage: UIImage?
        var ratingImage: UIImage?
        var showAttchmentIcon: Bool = false
        let from: String
        let subject: String
        let bodyPeek: String
        var isFlagged: Bool = false
        var isSeen: Bool = false
        var dateText: String
        
        init(withPreviewMessage pvmsg: PreviewMessage, senderContactImage: UIImage? = nil) {
            self.senderContactImage = senderContactImage
            showAttchmentIcon = pvmsg.hasAttachments
            from = pvmsg.from.userNameOrAddress
            subject = pvmsg.subject
            bodyPeek = pvmsg.bodyPeek
            isFlagged = pvmsg.isFlagged
            isSeen = pvmsg.isSeen
            dateText = pvmsg.dateSent.smartString()
        }
    }
    
    private var messages: SortedSet<PreviewMessage>?
    public var delegate: EmailListViewModelDelegate?
    private var _folderToShow: Folder?
    public private(set) var folderToShow: Folder? {
        set{
            if newValue == _folderToShow {
                return
            }
            _folderToShow = newValue
            resetViewModel()
        }
        get {
            return _folderToShow
        }
    }
    
    // MARK: Life Cycle
    
    init(delegate: EmailListViewModelDelegate? = nil, folderToShow: Folder? = nil) {
        self.delegate = delegate
        self.folderToShow = folderToShow
        MessageModelConfig.messageFolderDelegate = self
    }
    
    private func resetViewModel() {
        guard let folder = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data, no cry.")
            return
        }
        let messagesToDisplay = folder.allMessages()
        let previewMessages = messagesToDisplay.map { PreviewMessage(withMessage: $0) }
        let sortByDateSentAscending: SortedSet<PreviewMessage>.SortBlock =
        { (pvMsg1: PreviewMessage, pvMsg2: PreviewMessage) -> ComparisonResult in
            if pvMsg1.dateSent < pvMsg1.dateSent {
                return .orderedAscending
            } else if pvMsg1.dateSent > pvMsg1.dateSent {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
        messages = SortedSet(array: previewMessages, sortBlock: sortByDateSentAscending)
        delegate?.updateView()
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
        let session = PEPSessionCreator.shared.newSession()
        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating(session: session))
        let result = color.statusIcon()
        return result
    }
    
    func setFlagged(forIndexPath indexPath: IndexPath) {
        setFlagged(forIndexPath: indexPath, newValue: true)
    }
    
    func unsetFlagged(forIndexPath indexPath: IndexPath) {
        setFlagged(forIndexPath: indexPath, newValue: false)
    }
    
    func delete(forIndexPath indexPath: IndexPath) {
        guard let previewMessage = messages?.object(at: indexPath.row),
            let message = previewMessage.message() else {
                return
        }
        messages?.remove(object: previewMessage)
        message.delete()
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
        previewMessage.isFlagged = flagged
        message.imapFlags?.flagged = flagged
        DispatchQueue.main.async {
            message.save()
        }
    }

    // MARK: Filter
    
    public var isFilterEnabled = false {
        didSet {
            handleFilterEnabledSwitch()
        }
    }
    public var activeFilter : Filter? {
        get {
            guard let folder = folderToShow else {
                return nil
            }
            return folder.filter
        }
    }

    static let defaultFilterViewFilter = Filter.unread()
    private var _filterViewFilter: Filter = defaultFilterViewFilter
    private var filterViewFilter: Filter {
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

    private func setFilterViewFilter(filter:Filter) {
        if isFilterEnabled {
            let folderFilter = assuredFilterOfFolderToShow()
            folderFilter.without(filter: filterViewFilter)
            folderFilter.and(filter: filter)
            resetViewModel()
        }
        filterViewFilter = filter
    }

    private func handleFilterEnabledSwitch() {
        let folderFilter = assuredFilterOfFolderToShow()
        if isFilterEnabled {
            folderFilter.and(filter: filterViewFilter)
        } else {
            folderFilter.without(filter: filterViewFilter)
        }
        resetViewModel()
    }
    
    public func setSearchFilter(forSearchText txt: String = "") {
        if txt == "" {
            assuredFilterOfFolderToShow().removeSearchFilter()
        } else {
            let folderFilter = assuredFilterOfFolderToShow()
            folderFilter.removeSearchFilter()
            let searchFilter = Filter.search(subject: txt)
            folderFilter.and(filter: searchFilter)
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

    private func assuredFilterOfFolderToShow() -> Filter {
        guard let folder = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder.")
            return Filter.unified()
        }
        if folder.filter == nil{
            folder.resetFilter()
        }

        guard let folderFilter = folder.filter else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We just set the filter but do not have one?")
            return Filter.unified()
        }
        return folderFilter
    }
}

// MARK: - MessageFolderDelegate

extension EmailListViewModel: MessageFolderDelegate {
    func didCreate(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didCreateInternal(messageFolder: messageFolder)
        }
    }
    
    func didUpdate(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didUpdateInternal(messageFolder: messageFolder)
        }
    }
    
    func didDelete(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didDeleteInternal(messageFolder: messageFolder)
        }
    }
    
    private func didCreateInternal(messageFolder: MessageFolder) {
        if let message = messageFolder as? Message {
            // Is a Message (not a Folder)
            if let filter = folderToShow?.filter,
                !filter.fulfilsFilterConstraints(message: message) {
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
            delegate?.emailListViewModel(viewModel: self, didInsertDataAt: indexPath)
            
        }
    }
    
    private func didDeleteInternal(messageFolder: MessageFolder) {
        if let message = messageFolder as? Message {
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
            delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: indexPath)
        }
    }
    
    private func didUpdateInternal(messageFolder: MessageFolder) {
        if let message = messageFolder as? Message {
            // Is a Message (not a Folder)
            // Flag must have changed
            guard let indexExisting = indexOfPreviewMessage(forMessage: message) else {
                // We do not have this message in our model, so we do not have to update it
                return
            }
            guard let pvMsgs = messages else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
                return
            }
            pvMsgs.removeObject(at: indexExisting)
            let previewMessage = PreviewMessage(withMessage: message)
            let newIndex = pvMsgs.insert(object: previewMessage)
            if newIndex != indexExisting {
                // As We are removing and inserting the same message,
                // the resulting index must be the same as before.
                Log.shared.errorAndCrash(component: #function, errorString: "Inconsistant data")
            }
            let indexPath = IndexPath(row: indexExisting, section: 0)
            delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: indexPath)
        }
    }
}
