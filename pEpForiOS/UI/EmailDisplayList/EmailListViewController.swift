//
//  EmailListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import SwipeCellKit
import pEpIOSToolbox

class EmailListViewController: BaseTableViewController, SwipeTableViewCellDelegate {
    static let FILTER_TITLE_MAX_XAR = 20

    var model: EmailListViewModel? {
        didSet {
            model?.emailListViewModelDelegate = self
        }
    }

    public static let storyboardId = "EmailListViewController"
    private var lastSelectedIndexPath: IndexPath?

    let searchController = UISearchController(searchResultsController: nil)

    //swipe acctions types
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor

    private var swipeDelete : SwipeAction? = nil

    // MARK: - Outlets
    
    @IBOutlet weak var enableFilterButton: UIBarButtonItem!

    var textFilterButton: UIBarButtonItem = UIBarButtonItem(title: "",
                                                            style: .plain,
                                                            target: nil,
                                                            action: nil)

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelectionDuringEditing = true

        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        setupSearchBar()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
        if MiscUtil.isUnitTest() {
            return
        }

        setUpTextFilter()
        // Mark this folder as having been looked at by the user

        if let vm = model {
            updateFilterButtonView()
            vm.updateLastLookAt()
            if vm.checkIfSettingsChanged() {
                settingsChanged()
            }
        }
    }

    deinit {
         NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setup() {

        if let accountExists = model?.noAccountsExist(),
            accountExists {
            // No account exists. Show account setup.
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
            return
        }

        title = model?.getFolderName()
        let item = UIBarButtonItem.getPEPButton(
            action: #selector(showSettingsViewController),
            target: self)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
            target: nil,
            action: nil)
        toolbarItems?.append(contentsOf: [flexibleSpace,item])
        navigationController?.title = title
    }

    private func setUpTextFilter() {
        textFilterButton.isEnabled = false
        textFilterButton.action = #selector(showFilterOptions(_:))
        textFilterButton.target = self

        let fontSize:CGFloat = 10;
        let font:UIFont = UIFont.boldSystemFont(ofSize: fontSize);
        let attributes = [NSAttributedStringKey.font: font];

        textFilterButton.setTitleTextAttributes(attributes, for: UIControlState.normal)
    }

    // MARK: - Search Bar

    private func setupSearchBar() {
        definesPresentationContext = true
        configureSearchBar()
        if #available(iOS 11.0, *) {
            searchController.isActive = false
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
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

    /**
     Add the search bar when running on iOS 10 or earlier.
     */
    private func addSearchBar10() {
        tableView.tableHeaderView = searchController.searchBar
        tableView.setContentOffset(CGPoint(x: 0.0,
                                           y: searchController.searchBar.frame.size.height),
                                   animated: false)
    }

    // MARK: - Other

    private func weCameBackFromAPushedView() -> Bool {
        return model != nil
    }

    private func showComposeView() {
        performSegue(withIdentifier: SegueIdentifier.segueEditDraft, sender: self)
    }

    private func showEmail(forCellAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: self)
    }

    private func showNoMessageSelectedIfNeeded() {
        guard let splitViewController = self.splitViewController else {
            return
        }
        if splitViewController.isCollapsed {
            guard let vm = model else {
                Logger.frontendLogger.errorAndCrash("Invalid state")
                return
            }
            let unreadFilterActive = vm.unreadFilterEnabled()
            if navigationController?.topViewController != self && !unreadFilterActive {
                navigationController?.popViewController(animated: true)
            }
        } else {
            performSegue(withIdentifier: "showNoMessage", sender: nil)
        }
    }

    @objc private func settingsChanged() {
        model?.reloadData()
        tableView.reloadData()
    }

    // MARK: - Action Edit Button

    private var tempToolbarItems: [UIBarButtonItem]?
    private var editRightButton: UIBarButtonItem?
    var flagToolbarButton: UIBarButtonItem?
    var unflagToolbarButton: UIBarButtonItem?
    var readToolbarButton: UIBarButtonItem?
    var unreadToolbarButton: UIBarButtonItem?
    var deleteToolbarButton: UIBarButtonItem?
    var moveToolbarButton: UIBarButtonItem?

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
                                   action: #selector(flagToolbar(_:)))
        flagToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-unflagged")

        unflagToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItemStyle.plain,
                                            target: self,
                                            action: #selector(unflagToolbar(_:)))
        unflagToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-read")

        readToolbarButton = UIBarButtonItem(image: img,
                                   style: UIBarButtonItemStyle.plain,
                                   target: self,
                                   action: #selector(readToolbar(_:)))
        readToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-unread")

        unreadToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItemStyle.plain,
                                            target: self,
                                            action: #selector(unreadToolbar(_:)))
        unreadToolbarButton?.isEnabled = false

        img = UIImage(named: "folders-icon-trash")

        deleteToolbarButton = UIBarButtonItem(image: img,
                                     style: UIBarButtonItemStyle.plain,
                                     target: self,
                                     action: #selector(deleteToolbar(_:)))

        deleteToolbarButton?.isEnabled = false

        img = UIImage(named: "swipe-archive")

        moveToolbarButton = UIBarButtonItem(image: img,
                                     style: UIBarButtonItemStyle.plain,
                                     target: self,
                                     action: #selector(moveToolbar(_:)))

        moveToolbarButton?.isEnabled = false

        let pEp = UIBarButtonItem.getPEPButton(
            action: #selector(showSettingsViewController),
            target: self)
        toolbarItems = [flagToolbarButton, flexibleSpace, readToolbarButton,
                        flexibleSpace, deleteToolbarButton, flexibleSpace,
                        moveToolbarButton, flexibleSpace, pEp] as? [UIBarButtonItem]


        //right navigation button to ensure the logic
        let cancel = UIBarButtonItem(title: "Cancel",
                                     style: UIBarButtonItemStyle.plain,
                                     target: self,
                                     action: #selector(cancelToolbar(_:)))

        editRightButton = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = cancel

    }

    @objc private func showSettingsViewController() {
        UIUtils.presentSettings(on: self, appConfig: appConfig)
    }

    @IBAction func showFilterOptions(_ sender: UIBarButtonItem!) {
        performSegue(withIdentifier: .segueShowFilter, sender: self)
    }

    @IBAction func cancelToolbar(_ sender:UIBarButtonItem!) {
        showStandardToolbar()
        tableView.setEditing(false, animated: true)
    }

    @IBAction func flagToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            model?.markSelectedAsFlagged(indexPaths: selectedItems)
            selectedItems.forEach { (ip) in
                if let cell = self.tableView.cellForRow(at: ip) as? EmailListViewCell {
                    cell.isFlagged = true
                }
            }
        }
        cancelToolbar(sender)
    }

    @IBAction func unflagToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            model?.markSelectedAsUnFlagged(indexPaths: selectedItems)
            selectedItems.forEach { (ip) in
                if let cell = self.tableView.cellForRow(at: ip) as? EmailListViewCell {
                    cell.isFlagged = false
                }
            }
        }
        cancelToolbar(sender)
    }

    @IBAction func readToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            model?.markSelectedAsRead(indexPaths: selectedItems)
            selectedItems.forEach { (ip) in
                if let cell = self.tableView.cellForRow(at: ip) as? EmailListViewCell {
                    cell.isSeen = true
                }
            }
        }
        cancelToolbar(sender)
    }

    @IBAction func unreadToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            model?.markSelectedAsUnread(indexPaths: selectedItems)
            selectedItems.forEach { (ip) in
                if let cell = self.tableView.cellForRow(at: ip) as? EmailListViewCell {
                    cell.isSeen = false
                }
            }
        }
        cancelToolbar(sender)
    }

    @IBAction func moveToolbar(_ sender:UIBarButtonItem!) {
        performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
        cancelToolbar(sender)
    }

    @IBAction func deleteToolbar(_ sender:UIBarButtonItem!) {
        if let vm = model, let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            vm.deleteSelected(indexPaths: selectedIndexPaths)
            tableView.deleteRows(at: selectedIndexPaths, with: .automatic)
        }
        cancelToolbar(sender)
    }

    //recover the original toolbar and right button
    private func showStandardToolbar() {
        toolbarItems = tempToolbarItems
        navigationItem.rightBarButtonItem = editRightButton
    }

    private func moveSelectionIfNeeded(fromIndexPath: IndexPath, toIndexPath: IndexPath) {
        if lastSelectedIndexPath == fromIndexPath {
            lastSelectedIndexPath = toIndexPath
            resetSelection()
        }
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
        guard let vm = model else {
            Logger.frontendLogger.errorAndCrash("We should have a model here")
            return
        }
        vm.isFilterEnabled = !vm.isFilterEnabled
        if vm.isFilterEnabled {
            let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
                target: nil,
                action: nil)
            toolbarItems?.insert(textFilterButton, at: 1)
            toolbarItems?.insert(flexibleSpace, at: 1)
        } else {
            toolbarItems?.remove(at: 1)
            toolbarItems?.remove(at: 1)

        }
        updateFilterButtonView()
    }

    private func updateFilterButtonView() {
        guard let vm = model else {
            Logger.frontendLogger.errorAndCrash("We should have a model here")
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
        if let vm = model, var txt = vm.activeFilter?.title {
            if(txt.count > EmailListViewController.FILTER_TITLE_MAX_XAR){
                let prefix = txt.prefix(ofLength: EmailListViewController.FILTER_TITLE_MAX_XAR)
                txt = String(prefix)
                txt += "..."
            }
            if txt.isEmpty {
                txt = "none"
            }
            textFilterButton.title = "Filter by: " + txt
        }
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.rowCount ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EmailListViewCell.storyboardId,
                                                 for: indexPath)
        if let theCell = cell as? EmailListViewCell {
            theCell.delegate = self

            guard let viewModel = model?.viewModel(for: indexPath.row) else {
                return cell
            }
            theCell.configure(for:viewModel)
        } else {
            Logger.frontendLogger.errorAndCrash("dequeued wrong cell")
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt
        indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if model == nil {
            return nil
        }

        // Create swipe actions, taking the currently displayed folder into account
        var swipeActions = [SwipeAction]()

        guard let model = model else {
            Logger.frontendLogger.errorAndCrash("Should have VM")
            return nil
        }

        // Delete or Archive
        let destructiveAction = model.getDestructiveActtion(forMessageAt: indexPath.row)
        let archiveAction =
            SwipeAction(style: .destructive,
                        title: destructiveAction.title(forDisplayMode: .titleAndImage)) {
                [weak self] action, indexPath in
                guard let me = self else {
                    Logger.frontendLogger.lostMySelf()
                    return
                }

                me.deleteAction(forCellAt: indexPath)
                me.swipeDelete = action
        }
        configure(action: archiveAction, with: destructiveAction)
        swipeActions.append(archiveAction)

        // Flag
        let flagActionDescription = model.getFlagAction(forMessageAt: indexPath.row)
        if let flagActionDescription = flagActionDescription {
            let flagAction = SwipeAction(style: .default, title: "Flag") {
                [weak self] action, indexPath in
                guard let me = self else {
                    Logger.frontendLogger.lostMySelf()
                    return
                }
                me.flagAction(forCellAt: indexPath)
            }

            flagAction.hidesWhenSelected = true

            configure(action: flagAction, with: flagActionDescription)
            swipeActions.append(flagAction)
        }

        // More (reply++)
        let moreActionDescription = model.getMoreAction(forMessageAt: indexPath.row)

        if let moreActionDescription = moreActionDescription {
            // Do not add "more" actions (reply...) to drafts or outbox.
            let moreAction = SwipeAction(style: .default, title: "More") {
                [weak self] action, indexPath in
                guard let me = self else {
                    Logger.frontendLogger.lostMySelf()
                    return
                }
                me.moreAction(forCellAt: indexPath)
            }
            moreAction.hidesWhenSelected = true
            configure(action: moreAction, with: moreActionDescription)
            swipeActions.append(moreAction)
        }
        return (orientation == .right ?   swipeActions : nil)
    }

    func tableView(_ tableView: UITableView,
                   editActionsOptionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.transitionStyle = .border
        options.buttonSpacing = 11
        options.expansionStyle = .destructive(automaticallyDelete: false)
        return options
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? EmailListViewCell else {
            return
        }
        cell.clear()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if let vm = model, let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                vm.updatedItems(indexPaths: selectedIndexPaths)
            }
        } else {
            guard let model = model else {
                Logger.frontendLogger.errorAndCrash("No folder")
                return
            }
            lastSelectedIndexPath = indexPath
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            if model.shouldEditMessage() {
                showComposeView()
            } else {
                showEmail(forCellAt: indexPath)
            }
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
            Logger.frontendLogger.errorAndCrash("No model.")
            return
        }
        vm.fetchOlderMessagesIfRequired(forIndexPath: indexPath)
    }

    // MARK: - SwipeTableViewCellDelegate

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
            Logger.frontendLogger.errorAndCrash("No chance to remove filter, sorry.")
            return
        }
        vm.removeSearchFilter()
    }
}

// MARK: - EmailListViewModelDelegate

extension EmailListViewController: EmailListViewModelDelegate {
    func willReceiveUpdates(viewModel: EmailListViewModel) {
        tableView.beginUpdates()
    }

    func allUpdatesReceived(viewModel: EmailListViewModel) {
        tableView.endUpdates()
    }

    func showThreadView(for indexPath: IndexPath) {
       /* guard let splitViewController = splitViewController else {
            return
        }

        let storyboard = UIStoryboard(name: "Thread", bundle: nil)
        if splitViewController.isCollapsed {
            guard let message = model?.message(representedByRowAt: indexPath),
                let folder = folderToShow,
                let nav = navigationController,
                let vc: ThreadViewController =
                storyboard.instantiateViewController(withIdentifier: "threadViewController")
                    as? ThreadViewController
                else {
                    Logger.frontendLogger.errorAndCrash("Segue issue")
                    return
            }

            vc.appConfig = appConfig
            let viewModel = ThreadedEmailViewModel(tip:message, folder: folder)
            viewModel.emailDisplayDelegate = model
            vc.model = viewModel
            model?.currentDisplayedMessage = viewModel
            model?.updateThreadListDelegate = viewModel
            nav.viewControllers[nav.viewControllers.count - 1] = vc
        } else {
            showEmail(forCellAt: indexPath)
        }*/
    }

    func toolbarIs(enabled: Bool) {
        if model?.shouldShowToolbarEditButtons() ?? true {
            // Never enable those for outbox
            flagToolbarButton?.isEnabled = enabled
            unflagToolbarButton?.isEnabled = enabled
            readToolbarButton?.isEnabled = enabled
            unreadToolbarButton?.isEnabled = enabled
            moveToolbarButton?.isEnabled = enabled
        }
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

    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow
        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .automatic)
        tableView.endUpdates()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow ?? lastSelectedIndexPath

        if let swipeDelete = self.swipeDelete {
            swipeDelete.fulfill(with: .delete)
            self.swipeDelete = nil
        } else {
            tableView.beginUpdates()
            tableView.deleteRows(at: indexPaths, with: .automatic)
            tableView.endUpdates()
        }
        if let lastSelectedIndexPath = lastSelectedIndexPath,
            indexPaths.contains(lastSelectedIndexPath) {
            showNoMessageSelectedIfNeeded()
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow

        tableView.beginUpdates()
        tableView.reloadRows(at: indexPaths, with: .none)
        tableView.endUpdates()
        for indexPath in indexPaths {
            resetSelectionIfNeeded(for: indexPath)
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel,
                            didChangeSeenStateForDataAt indexPaths: [IndexPath]) {
        guard let isIphone = splitViewController?.isCollapsed, let vm = model else {
            Logger.frontendLogger.errorAndCrash("Invalid state")
            return
        }

        let unreadFilterActive = vm.unreadFilterEnabled()

        // If unread filter is active, /seen state updates require special handling ...

        if !isIphone && unreadFilterActive {
            // We do not update the seen status when both spitview views are shown and the list is
            // currently filtered by unread.
            return
        } else if isIphone && unreadFilterActive {
            vm.reloadData()
        } else {
            //  ... otherwize we forward to update
            emailListViewModel(viewModel: viewModel, didUpdateDataAt: indexPaths)
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow

        tableView.beginUpdates()
        tableView.moveRow(at: atIndexPath, to: toIndexPath)
        tableView.endUpdates()

        moveSelectionIfNeeded(fromIndexPath: atIndexPath, toIndexPath: toIndexPath)
    }

    func updateView() {
        tableView.dataSource = self
        tableView.reloadData()
        showNoMessageSelectedIfNeeded()
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

        let replyAllAction = createReplyAllAction(forRowAt: indexPath)

        let forwardAction = createForwardAction()
        let moveToFolderAction = createMoveToFolderAction()

        alertControler.addAction(cancelAction)
        alertControler.addAction(replyAction)

        if let theReplyAllAction = replyAllAction {
            alertControler.addAction(theReplyAllAction)
        }

        alertControler.addAction(forwardAction)
        alertControler.addAction(moveToFolderAction)

        if let popoverPresentationController = alertControler.popoverPresentationController {
            popoverPresentationController.sourceView = tableView
            let cellFrame = tableView.rectForRow(at: indexPath)
            let sourceRect = view.convert(cellFrame, from: tableView)
            popoverPresentationController.sourceRect = sourceRect

        }
        present(alertControler, animated: true, completion: nil)
    }

    // MARK: Action Sheet Actions

    private func createMoveToFolderAction() -> UIAlertAction {
        let title = NSLocalizedString("Move to Folder", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.performSegue(withIdentifier: .segueShowMoveToFolder, sender: me)
        }
    }

    func createCancelAction() -> UIAlertAction {
        let title = NSLocalizedString("Cancel", comment: "EmailList action title")
        return  UIAlertAction(title: title, style: .cancel) {
            [weak self] action in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.tableView.beginUpdates()
            me.tableView.setEditing(false, animated: true)
            me.tableView.endUpdates()
        }
    }

    func createReplyAction() ->  UIAlertAction {
        let title = NSLocalizedString("Reply", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) {
            [weak self] action in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.performSegue(withIdentifier: .segueReply, sender: me)
        }
    }

    func createReplyAllAction(forRowAt indexPath: IndexPath) ->  UIAlertAction? {
        if (model?.isReplyAllPossible(forRowAt: indexPath) ?? false) {
            let title = NSLocalizedString("Reply All", comment: "EmailList action title")
            return UIAlertAction(title: title, style: .default) {
                [weak self] action in
                guard let me = self else {
                    Logger.frontendLogger.lostMySelf()
                    return
                }
                me.performSegue(withIdentifier: .segueReplyAll, sender: me)
            }
        } else {
            return nil
        }
    }

    func createForwardAction() -> UIAlertAction {
        let title = NSLocalizedString("Forward", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) {
            [weak self] action in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.performSegue(withIdentifier: .segueForward, sender: me)
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
            Logger.frontendLogger.errorAndCrash("No data for indexPath!")
            return
        }
        guard let cell = self.tableView.cellForRow(at: indexPath) as? EmailListViewCell else {
            Logger.frontendLogger.errorAndCrash("No cell for indexPath!")
            return
        }
        if row.isFlagged {
            model?.unsetFlagged(forIndexPath: indexPath)
            cell.isFlagged = false
        } else {
            model?.setFlagged(forIndexPath: indexPath)
            cell.isFlagged = true
        }
    }

    func deleteAction(forCellAt indexPath: IndexPath) {
        model?.delete(forIndexPath: indexPath)
    }

    func moreAction(forCellAt indexPath: IndexPath) {
        showMoreActionSheet(forRowAt: indexPath)
    }
}

// MARK: - Segue handling

extension EmailListViewController {
    /**
     Enables manual account setup to unwind to the unified inbox.
     */
    @IBAction func segueUnwindAfterAccountCreation(segue:UIStoryboardSegue) {
        setup()
    }

    @IBAction func segueUnwindLastAccountDeleted(segue:UIStoryboardSegue) {
        setup()
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
        case segueEditDraft
        case segueShowFilter
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
                    Logger.frontendLogger.errorAndCrash("Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.message = message
            vc.folderShow = model?.getFolderToShow()
            vc.messageId = indexPath.row //that looks wrong
            vc.delegate = model as! EmailDisplayDelegate
            model?.currentDisplayedMessage = vc
      //  case .segueShowThreadedEmail:
        /*    guard let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? ThreadViewController,
                let indexPath = lastSelectedIndexPath,
                let folder = folderToShow else {
                    return
            }
            guard let message = model?.message(representedByRowAt: indexPath) else {
                Logger.frontendLogger.errorAndCrash("Segue issue")
                return
            }
            vc.appConfig = appConfig
            let viewModel = ThreadedEmailViewModel(tip:message, folder: folder)
            viewModel.emailDisplayDelegate = model
            vc.model = viewModel
            model?.currentDisplayedMessage = viewModel
            model?.updateThreadListDelegate = viewModel*/
        case .segueShowFilter:
            guard let destiny = segue.destination as? FilterTableViewController  else {
                Logger.frontendLogger.errorAndCrash("Segue issue")
                return
            }
            destiny.appConfig = appConfig
            destiny.filterDelegate = model
            destiny.inFolder = model?.getFolderIsUnified() ?? false
            destiny.filterEnabled = model?.getFolderFilters()
            destiny.hidesBottomBarWhenPushed = true
        case .segueAddNewAccount:
            guard
                let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? LoginViewController else {
                    Logger.frontendLogger.errorAndCrash("Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.delegate = self
            vc.hidesBottomBarWhenPushed = true
            break
        case .segueFolderViews:
            guard let vC = segue.destination as? FolderTableViewController  else {
                Logger.frontendLogger.errorAndCrash("Segue issue")
                return
            }
            vC.appConfig = appConfig
            //vC.hidesBottomBarWhenPushed = true
            break
        case .segueShowMoveToFolder:
            var selectedRows: [IndexPath] = []

            if let selectedItems = tableView.indexPathsForSelectedRows {
                selectedRows = selectedItems
            } else if let last = lastSelectedIndexPath {
                selectedRows.append(last)
            }

            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController
                else {
                    Logger.frontendLogger.errorAndCrash("No DVC?")
                    break
            }

            destination.viewModel
                = model?.getMoveToFolderViewModel(forSelectedMessages: selectedRows)
            destination.delegate = model
            destination.appConfig = appConfig
            break
        case .showNoMessage:
            //No initialization needed
            break
        default:
            Logger.frontendLogger.errorAndCrash("Unhandled segue")
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
            let composeMode = composeMode(for: segueId),
            let vm = model else {
                Logger.frontendLogger.errorAndCrash("composeViewController setup issue")
                return
        }
        composeVc.appConfig = appConfig

        if segueId != .segueCompose {
            // This is not a simple compose (but reply, forward or such),
            // thus we have to pass the original message.
            guard let indexPath = lastSelectedIndexPath else {
                    Logger.frontendLogger.errorAndCrash("Invalid state")
                    return
            }

            composeVc.viewModel = vm.composeViewModel(withOriginalMessageAt: indexPath,
                                                      composeMode: composeMode)
        }
        else {
            composeVc.viewModel = vm.composeViewModelForNewMessage()
        }
    }

    private func composeMode(for segueId: SegueIdentifier) -> ComposeUtil.ComposeMode? {
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
            return .normal
        default:
            return nil
        }
    }
}

// MARK: - LoginViewControllerDelegate

extension EmailListViewController: LoginViewControllerDelegate {
    func loginViewControllerDidCreateNewAccount(_ loginViewController: LoginViewController) {
        // Setup model after initial account setup
        setup()
    }
}

