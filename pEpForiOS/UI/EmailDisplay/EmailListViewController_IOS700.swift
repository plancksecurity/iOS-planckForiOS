//
//  EmailListViewController_IOS700.swift
//  pEp
//
//  Created by Andreas Buff on 28.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation

import MessageModel

protocol EmailListViewModelDelegate: TableViewUpdate {
    func emailListViewModel(viewModel: EmailListViewModel_IOS700, didInsertDataAt indexPath: IndexPath)
    func emailListViewModel(viewModel: EmailListViewModel_IOS700, didRemoveDataAt indexPath: IndexPath)
}

class EmailListViewModel_IOS700: FilterUpdateProtocol {
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
    private var folderToShow: Folder? {
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
    public private(set) var enabledFilters : Filter? = nil //BUFF: public?
    private var lastFilterEnabled: Filter?

    init(delegate: EmailListViewModelDelegate? = nil, folderToShow: Folder? = nil) {
        self.delegate = delegate
        self.folderToShow = folderToShow
    }

    func row(for indexPath: IndexPath) -> Row? {
        guard let previewMessage = messages?.object(at: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Problem getting data")
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
            return nil
        }
        return contactImageTool.identityImage(for: previewMessage.from)
    }

    func pEpRatingColorImage(forCellAt indexPath: IndexPath) -> UIImage? {
        guard let previewMessage = messages?.object(at: indexPath.row),
            let message = previewMessage.message() else {
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
                    folderToShow?.filter = Filter.removeSearchFilter(filter: f)
                }
            } else {
                updateFilter(filter: Filter.unified())
            }
        } else {
            if let text = searchText, text != "" {
                let f = Filter.search(subject: text)
                if filterEnabled {
                    f.and(filter: Filter.unread())
                    updateFilter(filter: f)
                } else {
                    updateFilter(filter: f)
                }
            }
        }
    }

    public func enableFilter() {
        if let lastFilter = lastFilterEnabled {
            updateFilter(filter: lastFilter)
        } else {
            updateFilter(filter: Filter.unread())
        }
    }

    public func updateFilter(filter: Filter) {
        if let temporalfilters = folderToShow?.filter {
            temporalfilters.and(filter: filter)
            enabledFilters = folderToShow?.updateFilter(filter: temporalfilters)
        } else {
            enabledFilters = folderToShow?.updateFilter(filter: filter)
        }

        //            self.delegate?.updateView() //BUFF:
    }

    public func resetFilters() {
        if let f = folderToShow {
            lastFilterEnabled = f.filter
            if f.isUnified {
                let _ = folderToShow?.updateFilter(filter: Filter.unified())
            } else {
                let _ = folderToShow?.updateFilter(filter: Filter.empty())
            }
        }
        //            self.delegate?.updateView() //BUFF:
    }
}

// MARK: - MessageFolderDelegate

extension EmailListViewModel_IOS700: MessageFolderDelegate { //BUFF: Shuld the model be the delegate? If so, it must be changed to a class
    public func didChange(messageFolder: MessageFolder) {
        GCD.onMainWait { //BUFF: assure we are not on main thread alread, to avoid deadlock
            self.didChangeInternal(messageFolder: messageFolder)
        }
    }

    private func didChangeInternal(messageFolder: MessageFolder) {
        guard let folder = folderToShow,
            let message = messageFolder as? Message,
            folder.contains(message: message, deletedMessagesAreContained: true) else {
                return
        }

        if message.isOriginal {
            // new message has arrived
            if let index = folder.indexOf(message: message) {
                let ip = IndexPath(row: index, section: 0)
                Log.info(
                    component: #function,
                    content: "insert message at \(index), \(folder.messageCount()) messages")
                delegate?.emailListViewModel(viewModel: self, didInsertDataAt: ip)
                //                tableView.insertRows(at: [ip], with: .automatic)
            } else {
                delegate?.updateView()
                //                tableView.reloadData()
            }
        } else if message.isGhost {
            //            if let vm = self
            //                    ,let cell = vm.cellFor(message: message), let ip = tableView.indexPath(for: cell)
            //            {
            //BUFF: handle delete
            //                    Log.info(
            //                        component: #function,
            //                        content: "delete message at \(index), \(folder.messageCount()) messages")
            //BUFF: get data consistant, fugure out indexPath, and call delegate:
            //                delegate?.emailListModel(emailListModel: self, didRemoveDataAt: <#T##IndexPath#>)
            //                    tableView.deleteRows(at: [ip], with: .automatic)
            //            } else {
            delegate?.updateView()
            //                tableView.reloadData()
            //            }
        } else {
            // other flags than delete must have been changed
            //            if let vm = self//, let cell = vm.cellFor(message: message)
            //            {
            //BUFF: handle update flags
            //                    cell.updateFlags(message: message)
            //            } else {
            delegate?.updateView()
            //                tableView.reloadData()
            //            }
        }
    }
}

class EmailListViewController_IOS700: BaseTableViewController {
    private var _folderToShow: Folder?
    var folderToShow: Folder? {
        set {
            if newValue == _folderToShow {
                return
            }
            _folderToShow = newValue
            // Update the model to data of new folder
            resetModel()
        }
        get {
            return _folderToShow
        }
    }

    func updateLastLookAt() {
        guard let saveFolder = folderToShow else {
            return
        }
        if saveFolder.isUnified {
            saveFolder.updateLastLookAt()
        } else {
            saveFolder.updateLastLookAtAndSave()
        }
    }

    private var model: EmailListViewModel_IOS700?

    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 10
        return createe
    }()
    private var operations = [IndexPath:Operation]()
    public static let storyboardId = "EmailListViewController"
    fileprivate var lastSelectedIndexPath: IndexPath?

    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Outlets

    @IBOutlet weak var enableFilterButton: UIBarButtonItem!
    @IBOutlet weak var textFilterButton: UIBarButtonItem!
    @IBOutlet var showFoldersButton: UIBarButtonItem!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Inbox", comment: "General name for (unified) inbox")
        UIHelper.emailListTableHeight(self.tableView)
        addSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
        if MiscUtil.isUnitTest() {
            return
        }

        MessageModelConfig.messageFolderDelegate = self as? MessageFolderDelegate
        //BUFF: TODO
        if let vm = model {
            self.textFilterButton.isEnabled = vm.filterEnabled
            updateFilterText()
        } else {
            self.textFilterButton.isEnabled = false
        }

        setDefaultColors()
        setup()
        updateView() //BUFF: check if triggered to often (model vs. here)

        // Mark this folder as having been looked at by the user
        updateLastLookAt()
        setupFoldersBarButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MessageModelConfig.messageFolderDelegate = nil
    }

    // MARK: - NavigationBar


    //BUFF: has to be tested
    private func hideFoldersNavigationBarButton() {
        self.showFoldersButton.isEnabled = false
        self.showFoldersButton.tintColor = UIColor.clear
    }
    //BUFF: has to be tested
    private func showFoldersNavigationBarButton() {
        self.showFoldersButton.isEnabled = false
        self.showFoldersButton.tintColor = nil
    }

    private func resetModel() {
        model = EmailListViewModel_IOS700(delegate: self, folderToShow: folderToShow)
    }

    private func setup() {
        // We have not been created to show a specific folder, thus we show unified inbox
        if folderToShow == nil {
            folderToShow = Folder.unifiedInbox()
        }

        if noAccountsExist() {
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        }
        guard let saveFolder = folderToShow else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We do not know what to show without a folder")
            return
        }
        self.title = realName(of: saveFolder)
    }

    private func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }

    private func setupFoldersBarButton() {
        if let size = navigationController?.viewControllers.count, size > 1 {
            hideFoldersNavigationBarButton()
        } else {
            showFoldersNavigationBarButton()
        }
    }

    private func addSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        tableView.setContentOffset(CGPoint(x: 0.0, y: 40.0), animated: false)
    }

    // MARK: - Other

    func updateFilterText() {
        if let vm = model, let txt = vm.enabledFilters?.text {
            textFilterButton.title = "Filter by: " + txt
        }
    }

    private func realName(of folder: Folder) -> String? {
        if folder.isUnified {
            return folder.name
        } else {
            return folder.realName
        }
    }

    func handleButtonFilter(enabled: Bool) {
        if enabled == false {
            textFilterButton.title = ""
            enableFilterButton.image = UIImage(named: "unread-icon")
        } else {
            enableFilterButton.image = UIImage(named: "unread-icon-active")
            updateFilterText()
        }
    }

    private func configure(cell: EmailListViewCell_IOS700, for indexPath: IndexPath) {
        // Configure lightweight stuff on main thread ...
        guard let saveModel = model else {
            return
        }
        guard let row = saveModel.row(for: indexPath) else {
            Log.shared.errorAndCrash(component: #function, errorString: "We should have a row here")
            return
        }
        cell.senderLabel.text = row.from
        cell.subjectLabel.text = row.subject
        cell.summaryLabel.text = row.bodyPeek
        cell.isFlagged = row.isFlagged
        cell.isSeen = row.isSeen
        cell.hasAttachment = row.showAttchmentIcon
        cell.dateLabel.text = row.dateText
        // Set image from cache if any
        cell.setContactImage(image: row.senderContactImage)

        let op = BlockOperation() { [weak self] in
            // ... and expensive computations in background
            guard let strongSelf = self else {
                // View is gone, nothing to do.
                return
            }

            var senderImage: UIImage?
            if row.senderContactImage == nil {
                // image for identity has not been cached yet, get and cache it
                senderImage = strongSelf.model?.senderImage(forCellAt: indexPath)
            }
            let pEpRatingImage = strongSelf.model?.pEpRatingColorImage(forCellAt: indexPath)

            // Set data on cell on main queue
            DispatchQueue.main.async {
                if senderImage != nil {
                    cell.contactImageView.image  = senderImage
                }
                if pEpRatingImage != nil {
                    cell.setPepRatingImage(image: pEpRatingImage)
                }
            }
        }
        queue(operation: op, for: indexPath)
    }

    // MARK: - Actions

    @IBAction func showUnreadButtonTapped(_ sender: UIBarButtonItem) {
        handlefilter()
    }

    func handlefilter() {
        //BUFF: TODO
        //        if let vm = viewModel {
        //            if vm.filterEnabled {
        //                vm.filterEnabled = false
        //                handleButtonFilter(enabled: false)
        //                if config != nil {
        //                    vm.resetFilters()
        //                }
        //            } else {
        //                vm.filterEnabled = true
        //                if config != nil {
        //                    vm.enableFilter()
        //                }
        //                handleButtonFilter(enabled: true)
        //            }
        //            self.textFilterButton.isEnabled = vm.filterEnabled
        //        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.rowCount ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EmailListViewCell_IOS700.storyboardId,
                                                       for: indexPath) as? EmailListViewCell_IOS700
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Wrong cell!")
                return UITableViewCell()
        }
        configure(cell: cell, for: indexPath)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, editActionsForRowAt
        indexPath: IndexPath)-> [UITableViewRowAction]? {
        //BUFF: TODO:

        guard let flagAction = createFlagAction(forCellAt: indexPath),
        let deleteAction = createDeleteAction(forCellAt: indexPath),
        let moreAction = createMoreAction(forCellAt: indexPath) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Error creating action.")
            return nil
        }

        return [deleteAction, flagAction, moreAction]
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelOperation(for: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: self)
    }

    // MARK: - Queue Handling

    private func queue(operation op:Operation, for indexPath: IndexPath) {
        operations[indexPath] = op
        queue.addOperation(op)
    }

    private func cancelOperation(for indexPath:IndexPath) {
        guard let op = operations.removeValue(forKey: indexPath) else {
            return
        }
        if !op.isCancelled  {
            op.cancel()
        }
    }

    // MARK: - Trival Cache

    override func didReceiveMemoryWarning() {
        model?.freeMemory()
    }
}

// MARK: - UISearchResultsUpdating, UISearchControllerDelegate

extension EmailListViewController_IOS700: UISearchResultsUpdating, UISearchControllerDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        if let vm = model {
            vm.filterContentForSearchText(searchText: searchController.searchBar.text!, clear: false)
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        if let vm = model {
            vm.filterContentForSearchText(clear: true)
        }
    }
}

// MARK: - EmailListModelDelegate

extension EmailListViewController_IOS700: EmailListViewModelDelegate {
    func emailListViewModel(viewModel: EmailListViewModel_IOS700, didInsertDataAt indexPath: IndexPath) {
        tableView.beginUpdates() //BUFF: need testing
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }

    func emailListViewModel(viewModel: EmailListViewModel_IOS700, didRemoveDataAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }

    func updateView() {
        //BUFF: uncomment
        //        if let m = model, let filter = folderToShow?.filter, filter.isDefault() {
        //            m.filterEnabled = false
        //            handleButtonFilter(enabled: false)
        //        }
        self.tableView.reloadData()
        //        if var vm = self.model, let filter = vm.folderToShow?.filter, filter.isDefault() {
        //            vm.filterEnabled = false
        //            handleButtonFilter(enabled: false)
        //        }
        //        self.tableView.reloadData()
    }
}

// MARK: - ActionSheet & ActionSheet Actions

extension EmailListViewController_IOS700 {
    func showMoreActionSheet(forRowAt indexPath: IndexPath) { //BUFF: HERE:
        lastSelectedIndexPath = indexPath
        let alertControler = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertControler.view.tintColor = .pEpGreen
        let cancelAction = createCancelAction()
        let replyAction = createReplyAction()
        let replyAllAction = createReplyAllAction()
        let forwardAction = createForwardAction()
        alertControler.addAction(cancelAction)
        alertControler.addAction(replyAction)
        alertControler.addAction(replyAllAction)
        alertControler.addAction(forwardAction)
        if let popoverPresentationController = alertControler.popoverPresentationController {
            popoverPresentationController.sourceView = tableView
        }
        present(alertControler, animated: true, completion: nil)
    }

    // MARK: Action Sheet Actions

    func createCancelAction() -> UIAlertAction {
        return  UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.tableView.beginUpdates()
            self.tableView.setEditing(false, animated: true)
            self.tableView.endUpdates()
        }
    }

    func createReplyAction() ->  UIAlertAction {
        return UIAlertAction(title: "Reply", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReply, sender: self)
        }
    }

    func createReplyAllAction() ->  UIAlertAction {
        return UIAlertAction(title: "Reply All", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyAll, sender: self)
        }
    }

    func createForwardAction() -> UIAlertAction {
        return UIAlertAction(title: "Forward", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueForward, sender: self)
        }
    }
}

// MARK: - TableViewCell Actions

extension EmailListViewController_IOS700 {
    private func createRowAction(image: UIImage?,
                                 action: @escaping (UITableViewRowAction, IndexPath) -> Void,
                         title: String) -> UITableViewRowAction {
        let rowAction = UITableViewRowAction(style: .normal, title: title, handler: action)
        if let theImage = image {
            let iconColor = UIColor(patternImage: theImage)
            rowAction.backgroundColor = iconColor
        }
        return rowAction
    }

    func createFlagAction(forCellAt indexPath: IndexPath) -> UITableViewRowAction? {
        guard let row = model?.row(for: indexPath) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data for indexPath!")
            return nil
        }
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            if row.isFlagged {
                model?.unsetFlagged(forIndexPath: indexPath)
            } else {
                model?.setFlagged(forIndexPath: indexPath)
            }
            tableView.beginUpdates()
            tableView.setEditing(false, animated: true)
            tableView.reloadRows(at: [indexPath], with: .none) //BUFF: glitches in UI. CHeck
            tableView.endUpdates()
        }
        let title: String
        if row.isFlagged{
            let unflagString = NSLocalizedString("Unflag", comment: "Message action (on swipe)")
            title = "\n\n\(unflagString)"
        } else {
            let flagString = NSLocalizedString("Flag", comment: "Message action (on swipe)")
            title = "\n\n\(flagString)"
        }
        return createRowAction(image: UIImage(named: "swipe-flag"), action: action, title: title)
    }

    func createDeleteAction(forCellAt indexPath: IndexPath) -> UITableViewRowAction? {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            tableView.beginUpdates()
            model?.delete(forIndexPath: indexPath) // mark for deletion/trash
            tableView.deleteRows(at: [indexPath], with: .none)
            tableView.endUpdates()
        }

        let title = NSLocalizedString("Delete", comment: "Message action (on swipe)")
        return createRowAction(image: UIImage(named: "swipe-trash"), action: action,
                               title: "\n\n\(title)")
    }

    func createMoreAction(forCellAt indexPath: IndexPath) -> UITableViewRowAction? {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            self.showMoreActionSheet(forRowAt: indexPath)
        }

        let title = NSLocalizedString("More", comment: "Message action (on swipe)")
        return createRowAction(image: UIImage(named: "swipe-more"),
                               action: action,
                               title: "\n\n\(title)")
    }
}

// MARK: - SegueHandlerType

extension EmailListViewController_IOS700: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueAddNewAccount
        case segueShowEmail
        case segueCompose
        case segueReply
        case segueReplyAll
        case segueForward
        case segueFilter
        case segueFolderViews
        case noSegue
    }

    /// Figures out the the appropriate account to use as sender ("from" field) when composing a mail.
    ///
    /// - Parameter vc: viewController to set the origin on
    private func origin() -> Identity? {
        guard let f = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder shown?")
            return Account.defaultAccount()?.user
        }
        if f.isUnified {
            //Set compose views sender ("from" field) to the default account.
            return Account.defaultAccount()?.user
        } else {
            //Set compose views sender ("from" field) to the account we are currently viewing emails for
            return f.account.user
        }
    }

    private func setup(composeViewController vc: ComposeTableViewController,
                       composeMode: ComposeTableViewController.ComposeMode = .normal,
                       originalMessage: Message? = nil) {
        vc.appConfig = appConfig
        vc.composeMode = composeMode
        vc.originalMessage = originalMessage
        vc.origin = origin()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueReply:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination, composeMode: .replyFrom,
                  originalMessage: message)
        case .segueReplyAll:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination, composeMode: .replyAll,
                  originalMessage: message)
        case .segueShowEmail:
            guard let vc = segue.destination as? EmailViewController,
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath) else { //BUFF: maybe remove message(representedByRowAt: and handle in dvc. First try background pepColor in dvc
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.message = message
            vc.folderShow = folderToShow
            vc.messageId = indexPath.row //BUFF: might be a problem. Re-think concept
        case .segueForward:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination, composeMode: .forward,
                  originalMessage: message)
        case .segueFilter:
            guard let destiny = segue.destination as? FilterTableViewController  else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return
            }
            destiny.appConfig = appConfig
            //            destiny.filterDelegate = model //BUFF: adjust FilterTableViewController
            destiny.inFolder = false
            destiny.filterEnabled = folderToShow?.filter
            destiny.hidesBottomBarWhenPushed = true
        case .segueAddNewAccount:
            guard let vc = segue.destination as? LoginTableViewController  else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return
            }
            vc.appConfig = appConfig
            vc.hidesBottomBarWhenPushed = true
            break
        case .segueFolderViews:
            guard let vC = segue.destination as? FolderTableViewController  else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return
            }
            vC.appConfig = appConfig
            vC.hidesBottomBarWhenPushed = true
            break
        case .segueCompose:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.rootViewController as? ComposeTableViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination)
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled segue")
            break
        }
    }

    @IBAction func segueUnwindAccountAdded(segue: UIStoryboardSegue) { //BUFF: dead code? looks empty & unconnected
    }
}
