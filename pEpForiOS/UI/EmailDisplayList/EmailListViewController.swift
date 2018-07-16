//
//  EmailListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import SwipeCellKit

class EmailListViewController: BaseTableViewController, SwipeTableViewCellDelegate {
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
        createe.maxConcurrentOperationCount = 5
        return createe
    }()
    private var operations = [IndexPath:Operation]()
    public static let storyboardId = "EmailListViewController"
    private var lastSelectedIndexPath: IndexPath?
    
    let searchController = UISearchController(searchResultsController: nil)

    //swipe acctions types
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor

    private var swipeDelete : SwipeAction? = nil

    /// Indicates that we must not trigger reloadData.
    private var loadingBlocked = false
    
    // MARK: - Outlets
    
    @IBOutlet weak var enableFilterButton: UIBarButtonItem!
    @IBOutlet weak var textFilterButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIHelper.emailListTableHeight(self.tableView)
        self.textFilterButton.isEnabled = false

        configureSearchBar()
        tableView.allowsMultipleSelectionDuringEditing = true
        
        if #available(iOS 11.0, *) {
            searchController.isActive = false
            self.navigationItem.searchController = searchController
            self.navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            addSearchBar10()

            if tableView.tableHeaderView == nil {
                tableView.tableHeaderView = searchController.searchBar
            }

            // some notifications to control when the app enter and recover from background
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didBecomeActiveInstallSearchBar10),
                name: NSNotification.Name.UIApplicationDidBecomeActive,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didBecomeInactiveUninstallSearchbar10),
                name: NSNotification.Name.UIApplicationDidEnterBackground,
                object: nil)
        }
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
        if MiscUtil.isUnitTest() {
            return
        }

        // Mark this folder as having been looked at by the user
        updateLastLookAt()

        if model != nil {
            updateFilterButtonView()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil)
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil)
    }

    /**
     Showing the search controller in versions iOS 10 and earlier.
     */
    @objc func didBecomeActiveInstallSearchBar10() {
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    /**
     Hide/remove the search controller in versions iOS 10 and earlier.
     */
    @objc func didBecomeInactiveUninstallSearchbar10() {
        tableView.tableHeaderView = nil
    }
    
    // MARK: - NavigationBar
    
    private func resetModel() {
        if let theFolder = folderToShow {
            model = EmailListViewModel(emailListViewModelDelegate: self,
                                       messageSyncService: appConfig.messageSyncService,
                                       folderToShow: theFolder)
        }
    }
    
    private func setup() {
        if noAccountsExist() {
            // No account exists. Show account setup.
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        } else if let vm = model {
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

        title = folderToShow?.localizedName
        self.navigationController?.title = title
    }

    private func weCameBackFromAPushedView() -> Bool {
        return model != nil
    }
    
    private func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }

    /**
     Configure the search controller, shared between iOS versions 11 and earlier.
     */
    private func configureSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
    }

    /**
     Add the search bar when running on iOS 10 or earlier.
     */
    private func addSearchBar10() {
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        tableView.setContentOffset(CGPoint(x: 0.0,
                                           y: searchController.searchBar.frame.size.height),
                                   animated: false)
    }
    
    // MARK: - Other

    private func showComposeView() {
        self.performSegue(withIdentifier: SegueIdentifier.segueEditDraft, sender: self)
    }

    private func showEmail(forCellAt indexPath: IndexPath) {
        guard let vm = model,
            let message = vm.message(representedByRowAt: indexPath) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model.")
            return
        }
        if message.numberOfMessagesInThread() > 0 {
            performSegue(withIdentifier: SegueIdentifier.segueShowThreadedEmail, sender: self)
        } else {
            performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: self)
        }
        vm.markRead(forIndexPath: indexPath)
    }

    private func showNotMessageSelectedIfNeeded() {
        guard let splitViewController = self.splitViewController else {
            return
        }
        if splitViewController.isCollapsed {
            if self.navigationController?.topViewController != self {
                navigationController?.popViewController(animated: true)
            }
        } else {
            self.performSegue(withIdentifier: "showNoMessage", sender: nil)
        }
    }

    // MARK: - Action Edit Button

    private var tempToolbarItems:  [UIBarButtonItem]?
    private var editRightButton: UIBarButtonItem?
    var flagToolbarButton : UIBarButtonItem?
    var unflagToolbarButton : UIBarButtonItem?
    var readToolbarButton : UIBarButtonItem?
    var unreadToolbarButton : UIBarButtonItem?
    var deleteToolbarButton : UIBarButtonItem?
    var moveToolbarButton : UIBarButtonItem?

    @IBAction func Edit(_ sender: Any) {

        showEditToolbar()
        tableView.setEditing(true, animated: true)

        //modificar toolbar
        //hacer aparecer check de marcado
        //hacer la accion solicitada
        //recuperar toolbar

    }

    private func showEditToolbar() {

        tempToolbarItems = toolbarItems

        // Flexible Space separation between the buttons
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
            target: nil,
            action: nil)

        var img = UIImage(named: "icon-flagged")

        flagToolbarButton = UIBarButtonItem(image: img,
                                   style: UIBarButtonItemStyle.plain,
                                   target: self,
                                   action: #selector(self.flagToolbar(_:)))
        flagToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-unflagged")

        unflagToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItemStyle.plain,
                                            target: self,
                                            action: #selector(self.unflagToolbar(_:)))
        unflagToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-read")

        readToolbarButton = UIBarButtonItem(image: img,
                                   style: UIBarButtonItemStyle.plain,
                                   target: self,
                                   action: #selector(self.readToolbar(_:)))
        readToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-unread")

        unreadToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItemStyle.plain,
                                            target: self,
                                            action: #selector(self.unreadToolbar(_:)))
        unreadToolbarButton?.isEnabled = false

        img = UIImage(named: "folders-icon-trash")

        deleteToolbarButton = UIBarButtonItem(image: img,
                                     style: UIBarButtonItemStyle.plain,
                                     target: self,
                                     action: #selector(self.deleteToolbar(_:)))

        deleteToolbarButton?.isEnabled = false

        img = UIImage(named: "swipe-archive")

        moveToolbarButton = UIBarButtonItem(image: img,
                                     style: UIBarButtonItemStyle.plain,
                                     target: self,
                                     action: #selector(self.moveToolbar(_:)))

        moveToolbarButton?.isEnabled = false

        let pEp = UIBarButtonItem(title: "p≡p",
                                   style: UIBarButtonItemStyle.plain,
                                   target: self,
                                   action: #selector(self.cancelToolbar (_:)))

        toolbarItems = [flagToolbarButton, flexibleSpace, readToolbarButton,
                        flexibleSpace, deleteToolbarButton, flexibleSpace,
                        moveToolbarButton, flexibleSpace, pEp] as? [UIBarButtonItem]


        //right navigation button to ensure the logic
        let cancel = UIBarButtonItem(title: "Cancel",
                                     style: UIBarButtonItemStyle.plain,
                                     target: self,
                                     action: #selector(self.cancelToolbar(_:)))

        editRightButton = self.navigationItem.rightBarButtonItem
        self.navigationItem.rightBarButtonItem = cancel

    }

    @IBAction func cancelToolbar(_ sender:UIBarButtonItem!) {
        showStandardToolbar()
        tableView.setEditing(false, animated: true)
    }

    @IBAction func flagToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = self.tableView.indexPathsForSelectedRows {
            model?.markSelectedAsFlagged(indexPaths: selectedItems)
        }
        cancelToolbar(sender)
    }

    @IBAction func unflagToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = self.tableView.indexPathsForSelectedRows {
            model?.markSelectedAsUnFlagged(indexPaths: selectedItems)
        }
        cancelToolbar(sender)
    }

    @IBAction func readToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = self.tableView.indexPathsForSelectedRows {
            model?.markSelectedAsRead(indexPaths: selectedItems)
        }
        cancelToolbar(sender)
    }

    @IBAction func unreadToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = self.tableView.indexPathsForSelectedRows {
            model?.markSelectedAsUnread(indexPaths: selectedItems)
        }
        cancelToolbar(sender)
    }

    @IBAction func moveToolbar(_ sender:UIBarButtonItem!) {
        self.performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
        cancelToolbar(sender)
    }

    @IBAction func deleteToolbar(_ sender:UIBarButtonItem!) {
        if let vm = model, let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
            vm.deleteSelected(indexPaths: selectedIndexPaths)
        }
        cancelToolbar(sender)
    }

    //recover the original toolbar and right button
    private func showStandardToolbar() {

        toolbarItems = tempToolbarItems
        self.navigationItem.rightBarButtonItem = editRightButton
    }

    private func resetSelectionIfNeeded(for indexPath: IndexPath) {
        if lastSelectedIndexPath == indexPath {
            resetSelection()
        }
    }

    private func resetSelection() {
        tableView.selectRow(at: lastSelectedIndexPath, animated: false, scrollPosition: .none)
    }

    // MARK: - Action Filter Button
    
    @IBAction func filterButtonHasBeenPressed(_ sender: UIBarButtonItem) {
        guard !loadingBlocked else {
            return
        }
        guard let vm = model else {
            Log.shared.errorAndCrash(component: #function, errorString: "We should have a model here")
            return
        }
        stopLoading()
        vm.isFilterEnabled = !vm.isFilterEnabled
        updateFilterButtonView()
    }
    
    private func updateFilterButtonView() {
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
    
    private func updateFilterText() {
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: EmailListViewCell.storyboardId,
            for: indexPath)

        if let theCell = cell as? EmailListViewCell {
            theCell.delegate = self
            guard let viewModel =  model?.viewModel(for: indexPath.row) else {
                return cell
            }
            theCell.configure(for:viewModel)
        } else {
            Log.shared.errorAndCrash(component: #function, errorString: "dequeued wrong cell")
        }

        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt
        indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {

        // Create swipe actions, taking the currently displayed folder into account
        var swipeActions = [SwipeAction]()

        // Get messages parent folder
        let parentFolder: Folder
        if let folder = folderToShow, !(folder is UnifiedInbox) {
            // Do not bother our imperformant MessageModel if we already know the parent folder
            parentFolder = folder
        } else {
            // folderToShow is unified inbox, fetch parent folder from DB.
            guard let vm = model,
                let folder = vm.message(representedByRowAt: indexPath)?.parent else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Dangling Message")
                    return nil
            }
            parentFolder = folder
        }

        // Delete or Archive
        let defaultIsArchive = parentFolder.defaultDestructiveActionIsArchive
        let titleDestructive = defaultIsArchive ? "Archive" : "Delete"
        let descriptorDestructive: SwipeActionDescriptor = defaultIsArchive ? .archive : .trash
        let archiveAction =
            SwipeAction(style: .destructive, title: titleDestructive) {action, indexPath in
                self.deleteAction(forCellAt: indexPath)
                self.swipeDelete = action
        }
        configure(action: archiveAction, with: descriptorDestructive)
        swipeActions.append(archiveAction)

        // Flag
        if folderIsDraft(parentFolder) {
            // Do not add "Flag" action to drafted mails.
            let flagAction = SwipeAction(style: .default, title: "Flag") { action, indexPath in
                self.flagAction(forCellAt: indexPath)
            }
            flagAction.hidesWhenSelected = true
            configure(action: flagAction, with: .flag)
            swipeActions.append(flagAction)
        }

        // More (reply++)
        if folderIsDraft(parentFolder) {
            // Do not add "more" actions (reply...) to drafted mails.
            let moreAction = SwipeAction(style: .default, title: "More") { action, indexPath in
                self.moreAction(forCellAt: indexPath)
            }
            moreAction.hidesWhenSelected = true
            configure(action: moreAction, with: .more)
            swipeActions.append(moreAction)
        }
        return (orientation == .right ?   swipeActions : nil)
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.transitionStyle = .border
        options.buttonSpacing = 11
        options.expansionStyle = .destructive(automaticallyDelete: false)
        return options
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelOperation(for: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if let vm = model, let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                vm.updatedItems(indexPaths: selectedIndexPaths)
            }
            return
        }
        guard let folder = folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder")
            return
        }
        lastSelectedIndexPath = indexPath
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)

        if folder.folderType == .drafts {
            showComposeView()
        } else {
            showEmail(forCellAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing, let vm = model {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                vm.updatedItems(indexPaths: selectedIndexPaths)
            } else {
                vm.updatedItems(indexPaths: [])
            }
        }
    }

    // Implemented to get informed about the scrolling position.
    // If the user has scrolled down (almost) to the end, we need to get older emails to display.
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        guard let vm = model else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model.")
            return
        }
        vm.fetchOlderMessagesIfRequired(forIndexPath: indexPath)
    }

    // MARK: - SwipeTableViewCellDelegate

    fileprivate func folderIsDraft(_ parentFolder: Folder) -> Bool {
        return parentFolder.folderType != .drafts
    }

    func configure(action: SwipeAction, with descriptor: SwipeActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)

        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }

    // MARK: - Queue Handling

    /// Cancels all operations and sets tableView.dataSource to nil.
    /// Used to avoid that an operation accesses an outdated view model
    private func stopLoading() {
        loadingBlocked = true
        tableView.dataSource = nil
        queue.cancelAllOperations()
        queue.waitUntilAllOperationsAreFinished()
    }
    
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

    // MARK: -

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

    func showThreadView(for indexPath: IndexPath) {
        showEmail(forCellAt: indexPath)
    }

    func toolbarIs(enabled: Bool) {
        flagToolbarButton?.isEnabled = enabled
        unflagToolbarButton?.isEnabled = enabled
        readToolbarButton?.isEnabled = enabled
        unreadToolbarButton?.isEnabled = enabled
        moveToolbarButton?.isEnabled = enabled
        deleteToolbarButton?.isEnabled = enabled
    }

    func showUnflagButton(enabled: Bool) {
        if enabled {

            if let button = unflagToolbarButton {
                toolbarItems?.remove(at: 0)
                toolbarItems?.insert(button, at: 0)
            }

        } else {
            if let button = flagToolbarButton {
                toolbarItems?.remove(at: 0)
                toolbarItems?.insert(button, at: 0)
            }
        }
    }

    func showUnreadButton(enabled: Bool) {
        if enabled {
            if let button = unreadToolbarButton {
                toolbarItems?.remove(at: 2)
                toolbarItems?.insert(button, at: 2)
            }
        } else {
            if let button = readToolbarButton {
                toolbarItems?.remove(at: 2)
                toolbarItems?.insert(button, at: 2)
            }
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPath: IndexPath) {
        Log.shared.info(component: #function, content: "\(model?.rowCount ?? 0)")
        lastSelectedIndexPath = tableView.indexPathForSelectedRow
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPath: IndexPath) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow ?? lastSelectedIndexPath

        if let swipeDelete = swipeDelete {
            swipeDelete.fulfill(with: .delete)
        } else {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
        Log.shared.info(component: #function, content: "\(model?.rowCount ?? 0)")
        if lastSelectedIndexPath == indexPath {
            showNotMessageSelectedIfNeeded()
        }

    }
    
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPath: IndexPath) {
        Log.shared.info(component: #function, content: "\(model?.rowCount ?? 0)")

        lastSelectedIndexPath = tableView.indexPathForSelectedRow

        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()

        resetSelectionIfNeeded(for: indexPath)
    }


    
    func emailListViewModel(viewModel: EmailListViewModel,
                            didUpdateUndisplayedMessage message: Message) {
        // ignore
    }

    func updateView() {
        loadingBlocked = false
        tableView.dataSource = self
        tableView.reloadData()
        showNotMessageSelectedIfNeeded()
    }
}

// MARK: - ActionSheet & ActionSheet Actions

extension EmailListViewController {
    func showMoreActionSheet(forRowAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        let alertControler = UIAlertController.pEpAlertController(
            title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = createCancelAction()
        let replyAction = createReplyAction()
        let replyAllAction = createReplyAllAction()
        let forwardAction = createForwardAction()
        let moveToFolderAction = createMoveToFolderAction()
        alertControler.addAction(cancelAction)
        alertControler.addAction(replyAction)
        alertControler.addAction(replyAllAction)
        alertControler.addAction(forwardAction)
        alertControler.addAction(moveToFolderAction)
        if let popoverPresentationController = alertControler.popoverPresentationController {
            popoverPresentationController.sourceView = tableView
            let cellFrame = tableView.rectForRow(at: indexPath)
            let sourceRect = self.view.convert(cellFrame, from: tableView)
            popoverPresentationController.sourceRect = sourceRect

        }
        present(alertControler, animated: true, completion: nil)
    }
    
    // MARK: Action Sheet Actions

    private func createMoveToFolderAction() -> UIAlertAction {
        let title = NSLocalizedString("Move to Folder", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { (action) in
            /*if let ip = self.lastSelectedIndexPath {
                self.model?.selectItem(indexPath: ip)
            }*/
            self.performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
        }
    }
    
    func createCancelAction() -> UIAlertAction {
        let title = NSLocalizedString("Cancel", comment: "EmailList action title")
        return  UIAlertAction(title: title, style: .cancel) { (action) in
            self.tableView.beginUpdates()
            self.tableView.setEditing(false, animated: true)
            self.tableView.endUpdates()
        }
    }
    
    func createReplyAction() ->  UIAlertAction {
        let title = NSLocalizedString("Reply", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReply, sender: self)
        }
    }
    
    func createReplyAllAction() ->  UIAlertAction {
        let title = NSLocalizedString("Reply All", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyAll, sender: self)
        }
    }
    
    func createForwardAction() -> UIAlertAction {
        let title = NSLocalizedString("Forward", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { (action) in
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
    
    func flagAction(forCellAt indexPath: IndexPath) {
        guard let row = model?.viewModel(for: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data for indexPath!")
            return
        }
        if row.isFlagged {
            model?.unsetFlagged(forIndexPath: indexPath)
        } else {
            model?.setFlagged(forIndexPath: indexPath)
        }
    }


    func deleteAction(forCellAt indexPath: IndexPath) {
        model?.delete(forIndexPath: indexPath)
    }
    
    func moreAction(forCellAt indexPath: IndexPath) {
        self.showMoreActionSheet(forRowAt: indexPath)
    }
}

// MARK: - Segue handling

extension EmailListViewController {

    /**
     Enables manual account setup to unwind to the unified inbox.
     */
    @IBAction func unwindToFolderView(segue:UIStoryboardSegue) { }

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
        case segueEditDraft
        case segueFilter
        case segueFolderViews
        case segueShowMoveToFolder
        case showNoMessage
        case segueShowThreadedEmail
        case noSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .segueReply,
             .segueReplyAll,
             .segueForward,
             .segueCompose,
             .segueEditDraft:
            setupComposeViewController(for: segue)
        case .segueShowEmail:
            guard let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? EmailViewController,
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.message = message
            vc.folderShow = folderToShow
            vc.messageId = indexPath.row //that looks wrong
            vc.delegate = model
            model?.currentDisplayedMessage = vc
        case .segueShowThreadedEmail:
            guard let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? ThreadViewController,
                let indexPath = lastSelectedIndexPath,
                let folder = folderToShow else {
                    return
            }
            guard let message = model?.message(representedByRowAt: indexPath) else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return
            }
            vc.appConfig = appConfig
            let viewModel = ThreadedEmailViewModel(tip:message, folder: folder)
            viewModel.emailDisplayDelegate = self.model
            vc.model = viewModel
            model?.currentDisplayedMessage = viewModel
            model?.updateThreadListDelegate = viewModel
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
            guard
                let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? LoginTableViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.delegate = self
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
        case .segueShowMoveToFolder:
            var selectedRows: [IndexPath] = []

            if let selectedItems = self.tableView.indexPathsForSelectedRows {
                selectedRows = selectedItems
            } else if let last = lastSelectedIndexPath{
                selectedRows.append(last)
            }

            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController,
                let messages = model?.messagesToMove(indexPaths: selectedRows)
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                    break
            }
            if let msgs = messages as? [Message] {
                let destinationvm = MoveToAccountViewModel(messages: msgs)
                destination.viewModel = destinationvm
            }
            destination.appConfig = appConfig
            break
        case .showNoMessage:
            //No initialization needed
            break
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled segue")
            break
        }
    }
    
    @IBAction func segueUnwindAccountAdded(segue: UIStoryboardSegue) {
        // nothing to do.
    }

    private func setupComposeViewController(for segue: UIStoryboardSegue) {
        let segueId = segueIdentifier(for: segue)
        guard
            let nav = segue.destination as? UINavigationController,
            let composeVc = nav.topViewController as? ComposeTableViewController,
            let composeMode = composeMode(for: segueId) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "composeViewController setup issue")
                return
        }
        composeVc.appConfig = appConfig
        composeVc.composeMode = composeMode
        composeVc.origin = folderToShow?.account.user
        if composeMode != .normal {
            // This is not a simple compose (but reply, forward or such),
            // thus we have to pass the original message.
            guard
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath) else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "No original message")
                    return
            }
            composeVc.originalMessage = message
        }
    }

    private func composeMode(for segueId: SegueIdentifier) -> ComposeTableViewController.ComposeMode? {
        switch segueId {
        case .segueReply:
            return .replyFrom
        case .segueReplyAll:
            return .replyAll
        case .segueForward:
            return .forward
        case .segueCompose:
            return .normal
        case .segueEditDraft:
            return .draft
        default:
            return nil
        }
    }
}

// MARK: - LoginTableViewControllerDelegate

extension EmailListViewController: LoginTableViewControllerDelegate {
    func loginTableViewControllerDidCreateNewAccount(
        _ loginTableViewController: LoginTableViewController) {
        // Setup model after initial account setup
        setup()
    }
}

/**
 Swipe configuration.
 */
enum SwipeActionDescriptor {
    case read, reply, more, flag, unflag, trash, archive

    func title(forDisplayMode displayMode: ButtonDisplayMode) -> String? {
        if displayMode == .imageOnly {
            return nil
        }

        switch self {
        case .read:
            return NSLocalizedString("Read", comment: "read button in slide-left menu")
        case .reply:
            return NSLocalizedString("Reply", comment: "read button in slide-left menu")
        case .more:
            return NSLocalizedString("More", comment: "more button in slide-left menu")
        case .flag:
            return NSLocalizedString("Flag", comment: "read button in slide-left menu")
        case .unflag:
            return NSLocalizedString("Unflag", comment: "read button in slide-left menu")
        case .trash:
            return NSLocalizedString("Trash", comment: "Trash button in slide-left menu")
        case .archive:
            return NSLocalizedString("Archive", comment: "Archive button in slide-left menu")
        }
    }

    func image(forStyle style: ButtonStyle, displayMode: ButtonDisplayMode) -> UIImage? {
        if displayMode == .titleOnly {
            return nil
        }

        let name: String
        switch self {
        case .read: name = "read"
        case .reply: name = "reply"
        case .more: name = "more"
        case .flag: name = "flag"
        case .unflag: name = "unflag"
        case .trash: name = "trash"
        case .archive: name = "archive"
        }

        return UIImage(named: "swipe-" + name + (style == .backgroundColor ? "" : "-circle"))
    }

    var color: UIColor {
        switch self {
        case .read: return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case .reply: return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case .more: return #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        case .flag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .unflag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .trash: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        case .archive: return UIColor.blue
        }
    }
}

enum ButtonDisplayMode {
    case titleAndImage, titleOnly, imageOnly
}

enum ButtonStyle {
    case backgroundColor, circular
}
