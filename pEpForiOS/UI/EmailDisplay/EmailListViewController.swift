//
//  EmailListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class EmailListViewController: BaseTableViewController {
    var folderToShow: Folder?

    func updateLastLookAt() {
        guard let saveFolder = folderToShow else {
            return
        }
        saveFolder.updateLastLookAt()
    }
    
    private var model: EmailListViewModel?
    
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
        self.textFilterButton.isEnabled = false
        addSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
        if MiscUtil.isUnitTest() {
            return
        }

        setDefaultColors()
        setup()
        
        // Mark this folder as having been looked at by the user
        updateLastLookAt()
        setupFoldersBarButton()
    }
    
    // MARK: - NavigationBar
    
    private func hideFoldersNavigationBarButton() {
        self.showFoldersButton.isEnabled = false
        self.showFoldersButton.tintColor = UIColor.clear
    }
    
    private func showFoldersNavigationBarButton() {
        self.showFoldersButton.isEnabled = true
        self.showFoldersButton.tintColor = nil
    }
    
    private func resetModel() {
        if folderToShow != nil {
            model = EmailListViewModel(delegate: self, folderToShow: folderToShow)
        }
    }
    
    private func setup() {
        /*if noAccountsExist() {
            // No account exists. Show account setup.
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        } else*/ if let vm = model {
            // We came back from e.g EmailView ...
            updateFilterText()
            // ... so we want to update "seen" status
            vm.reloadData()
        } else if folderToShow == nil {
            // We have not been created to show a specific folder, thus we show unified inbox
            folderToShow = UnifiedInbox()
            resetModel()
        } else if model == nil {
            // We still got no model, because:
            // - We are not coming back from a pushed view (for instance ComposeEmailView)
            // - We are not a UnifiedInbox
            // So we have been created to show a specific folder. Show it!
            resetModel()
        }

        self.title = realNameOfFolderToShow()
    }

    private func weCameBackFromAPushedView() -> Bool {
        return model != nil
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
        tableView.setContentOffset(CGPoint(x: 0.0, y: searchController.searchBar.frame.size.height), animated: false)
    }
    
    // MARK: - Other
    
    private func realNameOfFolderToShow() -> String? {
        return folderToShow?.realName
    }
    
    private func configure(cell: EmailListViewCell, for indexPath: IndexPath) {
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
                // image for identity has not been cached yet
                // Get and cache it here in the background ...
                senderImage = strongSelf.model?.senderImage(forCellAt: indexPath)

                // ... and set it on the main queue
                DispatchQueue.main.async {
                    if senderImage != nil && senderImage != cell.contactImageView.image {
                        cell.contactImageView.image  = senderImage
                    }
                }
            }

            let pEpRatingImage = strongSelf.model?.pEpRatingColorImage(forCellAt: indexPath)

            // In theory we want to set all data in *one* async call. But as pEpRatingColorImage takes
            // very long, we are setting the sender image seperatelly.
            DispatchQueue.main.async {
                if pEpRatingImage != nil {
                    cell.setPepRatingImage(image: pEpRatingImage)
                }
            }
        }
        queue(operation: op, for: indexPath)
    }
    
    // MARK: - Actions
    
    @IBAction func filterButtonHasBeenPressed(_ sender: UIBarButtonItem) {
        guard let vm = model else {
            Log.shared.errorAndCrash(component: #function, errorString: "We should have a model here")
            return
        }
        vm.isFilterEnabled = !vm.isFilterEnabled
        updateFilterButtonView()
    }
    
    func updateFilterButtonView() {
        guard let vm = model else {
            Log.shared.errorAndCrash(component: #function, errorString: "We should have a model here")
            return
        }
        
        textFilterButton.isEnabled = vm.isFilterEnabled
        if textFilterButton.isEnabled {
            enableFilterButton.image = UIImage(named: "unread-icon-active")
            updateFilterText()
        } else {
            textFilterButton.title = ""
            enableFilterButton.image = UIImage(named: "unread-icon")
        }
    }
    
    func updateFilterText() {
        if let vm = model, let txt = vm.activeFilter?.title {
            textFilterButton.title = "Filter by: " + txt
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.rowCount ?? 0
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EmailListViewCell.storyboardId,
                                                       for: indexPath) as? EmailListViewCell
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
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: self)
    }

    //BUFF:
    private let numRowsBeforeLastToTriggerFetchOder = 1
    private func triggerFetchOlder(lastDisplayedRow row: Int) -> Bool {
        guard let vm = model else {
            return false
        }
        return row >= vm.rowCount - numRowsBeforeLastToTriggerFetchOder
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {

        guard let folder = folderToShow,
            !(folder is UnifiedInbox) else {
                return //BUFF: check unified logic
        }
        if triggerFetchOlder(lastDisplayedRow: indexPath.row) {
            appConfig.messageSyncService.requestFetchOlderMessages(inFolder: folder)
        }
    }
    //FFUB
    
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
    
    override func didReceiveMemoryWarning() {
        model?.freeMemory()
    }
}

// MARK: - UISearchResultsUpdating, UISearchControllerDelegate

extension EmailListViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let vm = model, let searchText = searchController.searchBar.text else {
            return
        }
        vm.setSearchFilter(forSearchText: searchText)
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        guard let vm = model else {
            return
        }
        vm.removeSearchFilter()
    }
}

// MARK: - EmailListModelDelegate

extension EmailListViewController: EmailListViewModelDelegate {
    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    func updateView() {
        self.tableView.reloadData()
    }
}

// MARK: - ActionSheet & ActionSheet Actions

extension EmailListViewController {
    func showMoreActionSheet(forRowAt indexPath: IndexPath) {
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

extension EmailListViewController {
    private func createRowAction(image: UIImage?,
                                 action: @escaping (UITableViewRowAction, IndexPath) -> Void
        ) -> UITableViewRowAction {
        let rowAction = UITableViewRowAction(style: .normal, title: nil, handler: action)
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
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.endUpdates()
        }
        return createRowAction(image: UIImage(named: "swipe-flag"), action: action)
    }
    
    func createDeleteAction(forCellAt indexPath: IndexPath) -> UITableViewRowAction? {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            tableView.beginUpdates()
            model?.delete(forIndexPath: indexPath) // mark for deletion/trash
            tableView.deleteRows(at: [indexPath], with: .none)
            tableView.endUpdates()
        }

        return createRowAction(image: UIImage(named: "swipe-trash"), action: action)
    }
    
    func createMoreAction(forCellAt indexPath: IndexPath) -> UITableViewRowAction? {
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            self.showMoreActionSheet(forRowAt: indexPath)
        }

        return createRowAction(image: UIImage(named: "swipe-more"),
                               action: action)
    }
}

// MARK: - SegueHandlerType

extension EmailListViewController: SegueHandlerType {
    
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
    
    private func setup(composeViewController vc: ComposeTableViewController,
                       composeMode: ComposeTableViewController.ComposeMode = .normal,
                       originalMessage: Message? = nil) {
        vc.appConfig = appConfig
        vc.composeMode = composeMode
        vc.originalMessage = originalMessage
        vc.origin = folderToShow?.account.user
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
                let message = model?.message(representedByRowAt: indexPath) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.message = message
            vc.folderShow = folderToShow
            vc.messageId = indexPath.row //that looks wrong
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
            destiny.filterDelegate = model
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
    
    @IBAction func segueUnwindAccountAdded(segue: UIStoryboardSegue) {
        // nothing to do.
    }
}
