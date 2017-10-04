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
        if let updatee = folderToShow?.filter {
            updatee.and(filter: filter)
            folderToShow?.filter = updatee
            enabledFilter = updatee
        } else {
            folderToShow?.filter = filter
            enabledFilter = filter
        }

        resetViewModel() //BUFF:
    }
}

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
    public var filterEnabled = false //BUFF: public?
    public private(set) var enabledFilter : Filter? = nil //BUFF: public?
    private var lastFilterEnabled: Filter?
    private var lastSearchFilter: Filter?

    init(delegate: EmailListViewModelDelegate? = nil, folderToShow: Folder? = nil) {
        self.delegate = delegate
        self.folderToShow = folderToShow
        MessageModelConfig.messageFolderDelegate = self
    }

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

    func filterContentForSearchText(searchText: String? = nil, clear: Bool) {
        if clear {
            if filterEnabled {
                if let f = folderToShow?.filter {
                    f.removeSearchFilter()
                }
            } else {
                addFilter(Filter.unified())
            }
        } else {
            if let text = searchText, text != "" {
                let f = Filter.search(subject: text)
                if filterEnabled {
                    f.and(filter: Filter.unread())
                    addFilter(f)
                } else {
                    addFilter(f)
                }
            }
        }
    }

    public func enableFilter() {
        if let lastFilter = lastFilterEnabled {
            addFilter(lastFilter)
        } else {
            addFilter(Filter.unread())
        }
    }

    public func addSearchFilter(forSearchText txt: String = "") { //BUFF: here
        if txt != "" {
            let f = Filter.search(subject: txt)
            addFilter(f)
        }
    }

    public func removeSearchFilter() {
        guard let filter = folderToShow?.filter else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder.") //BUFF: should probaly not crash here
            return
        }
        filter.removeSearchFilter()
        resetViewModel()
    }

    public func resetFilters() {
        lastFilterEnabled = folderToShow?.filter
        folderToShow?.resetFilter()
        resetViewModel()
    }
}

// MARK: - MessageFolderDelegate

extension EmailListViewModel: MessageFolderDelegate {
    func didCreate(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didCreateInternal(messageFolder: messageFolder)
        }
    }

    //BUFF: move internals
    func didCreateInternal(messageFolder: MessageFolder) {
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

    func didDelete(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didDeleteInternal(messageFolder: messageFolder)
        }
    }

    func didDeleteInternal(messageFolder: MessageFolder) {
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

    func didUpdate(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didUpdateInternal(messageFolder: messageFolder)
        }
    }
    func didUpdateInternal(messageFolder: MessageFolder) {
        if let message = messageFolder as? Message {
            // Is a Message (not a Folder)
            //BUFF: test after IOS-748 is fixed (delegate not called for flag changes)
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

    public func didChange(messageFolder: MessageFolder) {
        //        GCD.onMainWait { //BUFF: assure we are not on main thread alread, to avoid deadlock
        //            self.didChangeInternal(messageFolder: messageFolder)
        //        }
        Log.shared.errorAndCrash(component: #function, errorString: "DO NOTHING")
    }

    //    private func didChangeInternal(messageFolder: MessageFolder) {
    //        guard let message = messageFolder as? Message else {
    //            Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
    //            return
    //        }
    //
    //        if message.isOriginal {
    ////            // new message has arrived
    ////            if let filter = folderToShow?.filter,
    ////                !filter.fulfilsFilterConstraints(message: message) {
    ////                // The message does not fit in current filter criteria. Ignore- and do not show it.
    ////                return
    ////            }
    ////
    ////            let previewMessage = PreviewMessage(withMessage: message)
    ////            guard let index = messages?.insert(object: previewMessage) else {
    ////                Log.shared.errorAndCrash(component: #function,
    ////                                         errorString: "We should be able to insert.")
    ////                return
    ////            }
    ////            let indexPath = IndexPath(row: index, section: 0)
    ////            delegate?.emailListViewModel(viewModel: self, didInsertDataAt: indexPath)
    //        } else if message.isGhost {
    ////            guard let indexExisting = indexOfPreviewMessage(forMessage: message) else {
    ////                // We do not have this message in our model, so we do not have to remove it
    ////                return
    ////            }
    ////            guard let pvMsgs = messages else {
    ////                Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
    ////                return
    ////            }
    ////            pvMsgs.removeObject(at: indexExisting)
    ////            let indexPath = IndexPath(row: indexExisting, section: 0)
    ////            delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: indexPath)
    //        } else {
    ////            //BUFF: test after IOS-748 is fixed (delegate not called for flag changes)
    ////            // Flag must have changed
    ////            guard let indexExisting = indexOfPreviewMessage(forMessage: message) else {
    ////                // We do not have this message in our model, so we do not have to update it
    ////                return
    ////            }
    ////            guard let pvMsgs = messages else {
    ////                Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
    ////                return
    ////            }
    ////            pvMsgs.removeObject(at: indexExisting)
    ////            let previewMessage = PreviewMessage(withMessage: message)
    ////            let newIndex = pvMsgs.insert(object: previewMessage)
    ////            if newIndex != indexExisting {
    ////                // As We are removing and inserting the same message,
    ////                // the resulting index must be the same as before.
    ////                Log.shared.errorAndCrash(component: #function, errorString: "Inconsistant data")
    ////            }
    ////            let indexPath = IndexPath(row: indexExisting, section: 0)
    ////            delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: indexPath)
    //        }
    //    }
}
