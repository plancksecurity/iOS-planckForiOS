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

protocol EmailListModelDelegate: TableViewUpdate {
    func emailListModel(emailListModel: EmailListModel, didInsertDataAt indexPath: IndexPath)
    func emailListModel(emailListModel: EmailListModel, didRemoveDataAt indexPath: IndexPath)
}

class EmailListModel: FilterUpdateProtocol {
    typealias MessageKey = String
    public struct TableViewModel {
        var rows: [Row]
        public struct Row {
            let identifier: MessageKey
            var senderImage: UIImage?
            var ratingImage: UIImage?
            var showAttchmentIcon: Bool = false
            let from: String
            let subject: String
            let bodyPeek: String
            var isFlagged: Bool = false
            var isSeen: Bool = false
            var date: String

            mutating func freeMemory() {
                senderImage = nil
                ratingImage = nil
            }
        }
    }

    public var tableViewModel: TableViewModel = TableViewModel(rows: [])
    public var delegate: EmailListModelDelegate?
    private var _folderToShow: Folder?
    private var folderToShow: Folder? {
        set{
            if newValue == _folderToShow {
                return
            }
            _folderToShow = newValue
            updateViewModel()
        }
        get {
            return _folderToShow
        }
    }
    public var filterEnabled = false
    public private(set) var enabledFilters : Filter? = nil
    private var lastFilterEnabled: Filter?

    init(delegate: EmailListModelDelegate? = nil, folderToShow: Folder? = nil) {
        self.delegate = delegate
        self.folderToShow = folderToShow
    }

    //BUFF:
    private func updateViewModel() {
        //BUFF: dispatch!
        guard let folder = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data, no cry.")
            return
        }
        let messagesToDisplay = folder.allMessages()
        var rows = [TableViewModel.Row]()
        for msg in messagesToDisplay {
            //BUFF: ??? senderImage hrere or config?
            //ratingImage ??

            guard let from = msg.from?.userNameOrAddress else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString:
                    "All mails in Email List must should have a \"from\" address, no?")
                continue
            }

            let row = TableViewModel.Row(identifier: key(forMessage: msg),
                                         senderImage: nil,
                                         ratingImage: nil,
                                         showAttchmentIcon: msg.attachments.count > 0,
                                         from: from,
                                         subject: msg.shortMessage ?? "",
                                         bodyPeek: msg.longMessage ?? "",
                                         isFlagged: msg.imapFlags?.flagged ?? false,
                                         isSeen: msg.imapFlags?.seen ?? false,
                                         date: msg.sent?.smartString() ?? "")
            rows.append(row)
        }
        tableViewModel.rows = rows
        delegate?.updateView()
    }

    //FFUB

    //BUFF: TODO

    private func key(forMessage msg: Message) -> MessageKey {
        let parentFolderName = msg.parent.name
        let accountAddress = msg.parent.account.user.address
        return "\(accountAddress)\(parentFolderName)\(msg.uuid)"
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

extension EmailListModel: MessageFolderDelegate { //BUFF: Shuld the model be the delegate? If so, it must be changed to a class
    func didChange(messageFolder: MessageFolder) {
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
                delegate?.emailListModel(emailListModel: self, didInsertDataAt: ip)
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
    let imageProvider = IdentityImageProvider()

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

//    struct UIState {
//        var isSynching: Bool = false
//    }

    private var model: EmailListModel?

    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 10
        return createe
    }()
    private var operations = [IndexPath:Operation]()
    public static let storyboardId = "EmailListViewController"

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
        //BUFF:
        //Create model here?
//        tableView.reloadData()
        //FFUB

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

//        //EmailListViewModel(config: config, delegate: self)
//        // If no model exists yet (as folderToShow has not been set yet), create one
//        if model == nil {
//            //BUFF: we should have the folder to show here already. Double check.
//            model = EmailListModel(delegate: self, folderToShow: nil)
//        }


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
        model = EmailListModel(delegate: self, folderToShow: folderToShow)
    }

    // MARK: - Setup
//    func updateModel() {
//        tableView.reloadData() //BUFF: Äh, no.
//    }

    func setup() {
//        // If no model exists yet (as folderToShow has not been set yet), create one
//        if folderToShow == nil {
//            folderToShow = Folder.unifiedInbox()
//        }

        //BUFF: should be obsolete, triggered when setting folderToShow
//        if model == nil {
//            model = EmailListModel(delegate: self, folderToShow: folderToShow)
//        }

        // We have not been created to show a specific folder, thus we show unified inbox
        if folderToShow == nil {
            folderToShow = Folder.unifiedInbox()
        }

        if Account.all().isEmpty { //BUFF: check performance
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        }
        guard let saveFolder = folderToShow else {
            return
        }
        self.title = realName(of: saveFolder)
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

    //BUFF: is default. not needed. We always have one section, maybe an empty one
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        if let _ = viewModel?.folderToShow {
//            return 1
//        }
//        return 0
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.tableViewModel.rows.count ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EmailListViewCell",
                                                       for: indexPath) as? EmailListViewCell_IOS700 else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong cell!")
            return UITableViewCell()
        }
//        let _ = cell.configureCell(config: config, indexPath: indexPath, session: session)
//        viewModel?.associate(cell: cell, position: indexPath.row)
        configure(cell: cell, for: indexPath)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, editActionsForRowAt
        indexPath: IndexPath)-> [UITableViewRowAction]? {
        //BUFF: TODO:
//        let cell = tableView.cellForRow(at: indexPath) as! EmailListViewCell
//        if let email = cell.messageAt(indexPath: indexPath, config: config) {
//            let flagAction = createFlagAction(message: email, cell: cell)
//            let deleteAction = createDeleteAction(message: email, cell: cell)
//            let moreAction = createMoreAction(message: email, cell: cell)
//            return [deleteAction, flagAction, moreAction]
//        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelOperation(for: indexPath)
    }

    //BUFF: from EmaiListCell
    private func configure(cell: EmailListViewCell_IOS700, for indexPath: IndexPath) {
        // Configure lightweight stuff on main thread ...
        guard let saveModel = model else {
            return
        }
        let rowModel = saveModel.tableViewModel.rows[indexPath.row]
        cell.senderLabel.text = rowModel.from
        cell.subjectLabel.text = rowModel.subject
        cell.summaryLabel.text = rowModel.bodyPeek
        let op = BlockOperation() { [weak self] in
            // ... and expensive computations in background
//            guard let strongSelf = self else {
//                // View is gone, nothing to do.
//                return
//            }
            DispatchQueue.main.async {
                cell.dateLabel.text = rowModel.date
            }


//            senderImage: nil,
//            ratingImage: nil,
//            showAttchmentIcon: msg.attachments.count > 0,
//            from: from,
//            subject: msg.shortMessage ?? "",
//            bodyPeek: msg.longMessage ?? "",
//            isFlagged: msg.imapFlags?.flagged ?? false,
//            isSeen: msg.imapFlags?.seen ?? false,
//            date: msg.sent?.smartString() ?? "")


            //BUFF: TODO
            //        self.session = theSession
            //        self.config = config
            //
            //        if let message = messageAt(indexPath: indexPath, config: config) {
            //            UIHelper.putString(message.from?.userNameOrAddress, toLabel: self.senderLabel)
            //            UIHelper.putString(message.shortMessage, toLabel: self.subjectLabel)
            //
            //            // Snippet
            //            if let text = message.longMessage {
            //                let theText = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
            //                UIHelper.putString(UIHelper.cleanHtml(theText), toLabel: self.summaryLabel)
            //            } else if let html = message.longMessageFormatted {
            //                var text = html.extractTextFromHTML()
            //                text = text?.replaceNewLinesWith(" ").trimmedWhiteSpace()
            //                UIHelper.putString(text, toLabel: self.summaryLabel)
            //            } else {
            //                UIHelper.putString(nil, toLabel: self.summaryLabel)
            //            }
            //
            //            if let originationDate = message.sent {
            //                UIHelper.putString(originationDate.smartString(), toLabel: self.dateLabel)
            //            } else {
            //                UIHelper.putString(nil, toLabel: self.dateLabel)
            //            }
            //
            //            attachmentIcon.isHidden = message.viewableAttachments().count > 0 ? false : true
            //            updateFlags(message: message)
            //            updatePepRating(message: message)
            //
            //            contactImageView.image = UIImage.init(named: "empty-avatar")
            //            identityForImage = message.from
            //            if let ident = identityForImage, let imgProvider = config?.imageProvider {
            //                imgProvider.image(forIdentity: ident) { img, ident in
            //                    if ident == self.identityForImage {
            //                        self.contactImageView.image = img
            //                    }
            //                }
            //            }
            //
            //            return message
            //        }
        }
        queue(operation: op, for: indexPath)
    }

//    /**
//     The message at the given position.
//     */
//    func haveSeen(message: Message) -> Bool {
//        return message.imapFlags?.seen ?? false
//    }
//
//    func isFlagged(message: Message) -> Bool {
//        return message.imapFlags?.flagged ?? false
//    }
//
//    func messageAt(indexPath: IndexPath, config: EmailListConfig?) -> Message? {
//        if let fol = config?.folder {
//            return fol.messageAt(index: indexPath.row)
//        }
//        return nil
//    }

//    func updatePepRating(message: Message) {
//        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating(session: theSession))
//        ratingImage.image = color.statusIcon()
//        ratingImage.backgroundColor = nil
//    }

//    func updateFlags(message: Message) {
//        let seen = haveSeen(message: message)
//        let flagged = isFlagged(message: message)
//
//        self.flaggedImageView.backgroundColor = nil
//        if flagged {
//            let fi = FlagImages.create(imageSize: flaggedImageView.frame.size)
//            self.flaggedImageView.isHidden = false
//            self.flaggedImageView.image = fi.flagsImage(message: message)
//        } else {
//            // show nothing
//            self.flaggedImageView.isHidden = true
//            self.flaggedImageView.image = nil
//        }
//
//        if let font = senderLabel.font {
//            let font = seen ? UIFont.systemFont(ofSize: font.pointSize):
//                UIFont.boldSystemFont(ofSize: font.pointSize)
//            setLabels(font: font)
//        }
//    }

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
        guard let m = model else {
            return
        }
        for row in m.tableViewModel.rows {
            var tmp = row
            tmp.freeMemory()
        }
    }
}

// MARK: - UISearchResultsUpdating, UISearchControllerDelegate

extension EmailListViewController_IOS700: UISearchResultsUpdating, UISearchControllerDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        if var vm = model {
            vm.filterContentForSearchText(searchText: searchController.searchBar.text!, clear: false)
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        if var vm = model {
            vm.filterContentForSearchText(clear: true)
        }
    }
}

// MARK: - EmailListModelDelegate

extension EmailListViewController_IOS700: EmailListModelDelegate {
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

    func emailListModel(emailListModel: EmailListModel, didInsertDataAt indexPath: IndexPath) {
        tableView.beginUpdates() //BUFF: need testing
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }

    func emailListModel(emailListModel: EmailListModel, didRemoveDataAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}

// MARK: - ActionSheet & ActionSheet Actions

extension EmailListViewController_IOS700 {
    func showMoreActionSheet(cell: EmailListViewCell) {
        let alertControler = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertControler.view.tintColor = .pEpGreen
        let cancelAction = createCancelAction()
        let replyAction = createReplyAction(cell: cell)
        let replyAllAction = createReplyAllAction(cell: cell)
        let forwardAction = createForwardAction(cell: cell)
        alertControler.addAction(cancelAction)
        alertControler.addAction(replyAction)
        alertControler.addAction(replyAllAction)
        alertControler.addAction(forwardAction)
        if let popoverPresentationController = alertControler.popoverPresentationController {
            popoverPresentationController.sourceView = cell
        }
        present(alertControler, animated: true, completion: nil)
    }

    // MARK: Action Sheet Actions

    func createCancelAction() -> UIAlertAction {
        return  UIAlertAction(title: "Cancel", style: .cancel) { (action) in}
    }

    func createReplyAction(cell: EmailListViewCell) ->  UIAlertAction {
        return UIAlertAction(title: "Reply", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReply, sender: cell)
        }
    }

    func createReplyAllAction(cell: EmailListViewCell) ->  UIAlertAction {
        return UIAlertAction(title: "Reply All", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyAll, sender: cell)
        }
    }

    func createForwardAction(cell: EmailListViewCell) -> UIAlertAction {
        return UIAlertAction(title: "Forward", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueForward, sender: cell)
        }
    }
}

// MARK: - TableViewCell Actions

extension EmailListViewController_IOS700 {
    func createRowAction(cell: EmailListViewCell,
                         image: UIImage?, action: @escaping (UITableViewRowAction, IndexPath) -> Void,
                         title: String) -> UITableViewRowAction {
        let rowAction = UITableViewRowAction(
            style: .normal, title: title, handler: action)

        if let theImage = image {
            let iconColor = UIColor(patternImage: theImage)
            rowAction.backgroundColor = iconColor
        }

        return rowAction
    }

    func createFlagAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            if message.imapFlags == nil {
                Log.warn(component: #function, content: "message.imapFlags == nil")
            }
            if cell.isFlagged(message: message) {
                message.imapFlags?.flagged = false
            } else {
                message.imapFlags?.flagged = true
            }
            message.save()
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }

        let flagString = NSLocalizedString("Flag", comment: "Message action (on swipe)")
        var title = "\n\n\(flagString)"
        let unflagString = NSLocalizedString("Unflag", comment: "Message action (on swipe)")
        if message.imapFlags?.flagged ?? true {
            title = "\n\n\(unflagString)"
        }

        return createRowAction(
            cell: cell, image: UIImage(named: "swipe-flag"), action: action, title: title)
    }

    func createDeleteAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {
        //BUFF:
//        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
//            guard let message = cell.messageAt(indexPath: indexPath, config: self.config) else {
//                return
//            }
//
//            message.delete() // mark for deletion/trash
//            self.tableView.reloadData()
//        }
//
//        let title = NSLocalizedString("Delete", comment: "Message action (on swipe)")
//        return createRowAction(
//            cell: cell, image: UIImage(named: "swipe-trash"), action: action,
//            title: "\n\n\(title)")
        return UITableViewRowAction() //BUFF: delete
    }

    func createMarkAsReadAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            if cell.haveSeen(message: message) {
                message.imapFlags?.seen = false
            } else {
                message.imapFlags?.seen = true
            }
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }

        var title = NSLocalizedString(
            "Unread", comment: "Message action (on swipe)")
        if !cell.haveSeen(message: message) {
            title = NSLocalizedString(
                "Read", comment: "Message action (on swipe)")
        }

        let isReadAction = createRowAction(cell: cell, image: nil, action: action,
                                           title: title)
        isReadAction.backgroundColor = UIColor.blue

        return isReadAction
    }

    func createMoreAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            self.showMoreActionSheet(cell: cell)
        }

        let title = NSLocalizedString("More", comment: "Message action (on swipe)")
        return createRowAction(
            cell: cell, image: UIImage(named: "swipe-more"), action: action,
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

    private func currentMessage(senderCell: Any?) -> (Message, IndexPath)? {
        //BUFF:
//        if let cell = senderCell as? EmailListViewCell,
//            let indexPath = self.tableView.indexPath(for: cell),
//            let message = cell.messageAt(indexPath: indexPath, config: config) {
//            return (message, indexPath)
//        }
        return nil
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
                let (theMessage, _) = currentMessage(senderCell: sender) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination, composeMode: .replyFrom,
                  originalMessage: theMessage)
        case .segueReplyAll:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let (theMessage, _) = currentMessage(senderCell: sender)  else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination, composeMode: .replyAll,
                  originalMessage: theMessage)
        case .segueShowEmail:
            guard let vc = segue.destination as? EmailViewController,
                let (theMessage, indexPath) = currentMessage(senderCell: sender) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.message = theMessage
            vc.folderShow = folderToShow
            vc.messageId = indexPath.row
        case .segueForward:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let (theMessage, _) = currentMessage(senderCell: sender) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            setup(composeViewController: destination, composeMode: .forward,
                  originalMessage: theMessage)
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
