//
//  EmailListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import SwipeCellKit
import PlanckToolbox
import MessageModel


final class EmailListViewController: UIViewController {

    @IBOutlet public weak var tableView: UITableView!
    @IBOutlet public weak var tableViewBottomConstraint: NSLayoutConstraint!
    public static let storyboardId = "EmailListViewController"

    /// Stuff that must be done once only in viewWillAppear
    private var doOnce: (()-> Void)?
    /// With this tag we recognize our own created flexible space buttons, for easy removal later.
    private let flexibleSpaceButtonItemTag = 77
    /// Our own factory method for creating pEp bar button items,
    /// tagged so we recognize them later, for easy removal.
    private lazy var settingsBarButton: UIBarButtonItem = {
        return UIBarButtonItem.getPEPButton(
            action: #selector(showSettingsViewController),
            target: self)
    }()

    private var editButton: UIBarButtonItem?
    // Right toolbar button for dismiss modal view in Drafts Preview mode
    private var dismissButton: UIBarButtonItem?
    private var flagToolbarButton: UIBarButtonItem?
    private var unflagToolbarButton: UIBarButtonItem?
    private var readToolbarButton: UIBarButtonItem?
    private var unreadToolbarButton: UIBarButtonItem?
    private var deleteToolbarButton: UIBarButtonItem?
    private var moveToolbarButton: UIBarButtonItem?
    private var enableFilterButton: UIBarButtonItem?
    private let textFilterButton = UIBarButtonItem(title: "",
                                                   style: .plain,
                                                   target: nil,
                                                   action: nil)

    public var viewModel: EmailListViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    private var lastSelectedIndexPath: IndexPath? {
        get {
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return nil
            }
            return vm.lastSelectedIndexPath
        }
        set {
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return
            }
            vm.lastSelectedIndexPath = newValue
        }
    }

    private let searchController = UISearchController(searchResultsController: nil)

    // swipe actions types
    private let buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    private let buttonStyle: ButtonStyle = .backgroundColor

    private var swipeDelete: SwipeAction? = nil

    private let refreshController = UIRefreshControl()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title?.isAccessibilityElement = true
        subscribeForKeyboardNotifications()
        edgesForExtendedLayout = .all
        setSeparator()
        registerNotifications()
        doOnce = { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let vm = me.viewModel else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            me.showNoMessageSelected()

            me.updateFilterButton()
            vm.handleViewDidLoad()
            me.tableView.reloadData()
            me.doOnce = nil
        }
        setup()
        setupTextFilter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
        navigationController?.navigationItem.leftBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifier.backButton
        navigationController?.navigationItem.leftBarButtonItem?.isAccessibilityElement = true
        navigationController?.navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifier.editButton
        navigationController?.navigationItem.rightBarButtonItem?.isAccessibilityElement = true

        setBackButtonAccessibilityLabel()
        if MiscUtil.isUnitTest() {
            return
        }

        lastSelectedIndexPath = nil

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM.")
            return
        }

        if !vm.showLoginView {
            doOnce?()
        }
        updateFilterText()
        updateEditButton()
        vm.updateLastLookAt()
        updateFilterButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleBannerIfNeeded()
        vm.moveMailsToSuspiciousIfPossible()
        
        let data = KeySyncHandshakeData(fingerprintLocal: "B787  8D1A C48D E573 5F92 509F 635D AB1B  B749", fingerprintOther: "A157 1A8D 8DC4 73E5 95F2 0F59 6D35 CB1A A8B7")
        UIUtils.showKeySyncWizard(keySyncHandshakeData: data) { action in
            print(action)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.visibleCells.forEach {
            if let cell = $0 as? SwipeTableViewCell {
                cell.hideSwipe(animated: true)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (isMovingFromParent) {
            mergeUIState()
        }
    }

    deinit {
        unsubscribeAll()
    }

    // MARK: - Setup

    private func setup() {
        tableView.separatorInset = .zero
        tableView.delegate = self
        tableView.dataSource = self
        // rm seperator lines for empty view/cells
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelectionDuringEditing = true

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        if vm.showLoginView {
            showLoginScreen()
            return
        }

        ///if we are in setup and the folder is unifiedInbox
        ///we have to reload the unifiedInbox to ensure that all the accounts are present.
        if vm.folderToShow is UnifiedInbox {
            viewModel = EmailListViewModel(delegate: self, folderToShow: UnifiedInbox())
        }
        setupSearchBar()
        setupNavigationBar()
        setupRefreshControl()
    }

    private func setupRefreshControl() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        guard vm.shouldShowRefreshController else {
            //Valid case: we might be in a local folder.
            return
        }
        if UITraitCollection.current.userInterfaceStyle == .light {
            refreshController.tintColor = UIColor.primary()
        }

        refreshController.addTarget(self, action: #selector(refreshView), for: .valueChanged)
        // Apples default UIRefreshControl implementation is buggy when using a UITableView in a
        // UIViewController (instead of a UITableViewController). The UI freaks out while
        // refreshing and after refreshing the UI is messed (refreshControl and search bar above
        // first tableView cell. Adding the refreshControl as subview of UITableView works around
        // this issue without changing the NavigationBar's "show/hide SearchField when scrolling"
        // behaviour. Do NOT use the intended (`tableView.refreshControl`) way to set the refresh
        // controll up! = refreshController
         tableView.addSubview(refreshController)
    }

    private func setupTextFilter() {
        textFilterButton.accessibilityIdentifier = AccessibilityIdentifier.filterButton
        textFilterButton.isEnabled = false
        textFilterButton.action = #selector(showFilterOptions)
        textFilterButton.target = self

        let fontSize = CGFloat(10.0)
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        textFilterButton.setTitleTextAttributes(attributes, for: .normal)
        textFilterButton.setTitleTextAttributes(attributes, for: .selected)
    }

    private func setupNavigationBar() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        title = vm.folderName
        navigationController?.title = title

        editButton = UIBarButtonItem(title: NSLocalizedString("Edit",
                                                                   comment: "Edit - Right bar button item in Email List"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(editButtonPressed))
        editButton?.accessibilityIdentifier = AccessibilityIdentifier.editButton

        dismissButton = UIBarButtonItem(title: NSLocalizedString("Cancel",
                                                                      comment: "Cancel - right bar button item in Email List to dismiss a view for Drafts Preview mode"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(dismissButtonPressed(_:)))
        dismissButton?.accessibilityIdentifier = AccessibilityIdentifier.cancelButton

        showStandardToolbar()
    }

    // MARK: - Search Bar

    private func setupSearchBar() {
        searchController.isActive = true
        searchController.searchBar.accessibilityIdentifier = AccessibilityIdentifier.searchBar
        searchController.searchBar.isAccessibilityElement = true
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    /// Called on pull-to-refresh triggered
    @objc private func refreshView() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.fetchNewMessages() { [weak self] in
            guard let me = self else {
                // Loosing self is a valid case here. The view might have been dismissed.
                return
            }
            // We intentionally do NOT use me.tableView.refreshControl?.endRefreshing() here.
            // See comments in `setupRefreshControl` for details.
            me.refreshController.endRefreshing()
            me.updateEditButton()
        }
    }

    // MARK: - Other

    private func showEditDraftComposeView() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM!")
            return
        }
        guard let indexPath = lastSelectedIndexPath else {
            Log.shared.warn("No IndexPath. (Can happen if the message the user wanted to reply to has been deleted in between performeSeque and here)")
            return
        }
        guard let composeVM = vm.composeViewModel(forMessageRepresentedByItemAt: indexPath,
                                                  composeMode: .normal) else {
            Log.shared.errorAndCrash(message: "No VM! (Compose View Model for this indexPath doesn't exist!)")
            return
        }
        presentComposeViewToEditDraft(composeVM: composeVM)
    }

    private func showNoMessageSelected() {
        // Note that this message can appear after the inital deployment
        // (account creation) while there is still no message in the list,
        // and it's not even known if there will be any.
        showEmptyDetailViewIfApplicable(message: NSLocalizedString(
            "Nothing selected",
            comment: "No messages has been selected for detail view"))
    }

    private func showLoginScreen() {
        performSegue(withIdentifier:.segueAddNewAccount, sender: self)
    }

    // MARK: - Action Dismiss for Cancel Button in Drafts Preview mode

    @IBAction private func dismissButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: - Action Edit Button

    private func updateEditButton() {
        guard let vm = viewModel else  {
            //Valid case: might be dismissed.
            return
        }
        guard let editButton = editButton else {
            Log.shared.errorAndCrash(message: "editButton in navigation is not initialized!")
            return
        }
        let primary = UIColor.primary()
        let editButtonDisabled = vm.rowCount == 0
        editButton.isEnabled = editButtonDisabled ? false : true
        editButton.tintColor = editButtonDisabled ? .clear: primary
    }

    private func showEditToolbar() {
        func getButtonItem(img: UIImage?, action: Selector, accessibilityIdentifier: String) -> UIBarButtonItem {
            let button = UIBarButtonItem(image: img, style: .plain, target: self, action: action)
            button.accessibilityIdentifier = accessibilityIdentifier
            return button
        }
        // Flexible Space separation between the buttons
        let flexibleSpace = createFlexibleBarButtonItem()
        flagToolbarButton = getButtonItem(img: UIImage(named: "icon-flagged"), action: #selector(flagToolbar), accessibilityIdentifier: "Flag button")
        unflagToolbarButton = getButtonItem(img: UIImage(named: "icon-unflagged"), action: #selector(unflagToolbar), accessibilityIdentifier: "Unflag button")
        readToolbarButton = getButtonItem(img: UIImage(named: "icon-read"), action: #selector(readToolbar), accessibilityIdentifier: "Read button")
        unreadToolbarButton = getButtonItem(img: UIImage(named: "icon-unread"), action: #selector(unreadToolbar), accessibilityIdentifier: "Unread button")
        deleteToolbarButton = getButtonItem(img: UIImage(named: "folders-icon-trash"), action: #selector(deleteToolbar), accessibilityIdentifier: "Delete button")
        moveToolbarButton = getButtonItem(img: UIImage(named: "swipe-archive"), action: #selector(moveToolbar), accessibilityIdentifier: "Move button")

        toolbarItems = [flagToolbarButton, flexibleSpace,
                        readToolbarButton, flexibleSpace,
                        deleteToolbarButton, flexibleSpace,
                        moveToolbarButton, flexibleSpace,
                        settingsBarButton] as? [UIBarButtonItem]

        //right navigation button to ensure the logic
        let cancelTitle = NSLocalizedString("Cancel", comment: "EmailList: Cancel edit mode button title")
        let cancel = UIBarButtonItem(title: cancelTitle,
                                     style: .plain,
                                     target: self,
                                     action: #selector(cancelToolbar))
        cancel.accessibilityIdentifier = AccessibilityIdentifier.cancelButton
        navigationItem.rightBarButtonItem = cancel
    }

    @objc private func showSettingsViewController() {
        UIUtils.showSettings()
    }

    @IBAction private func editButtonPressed() {
        mergeUIState()
        showEditToolbar()
        tableView.setEditing(true, animated: true)
        updateBackButton(isTableViewEditing: tableView.isEditing)
    }

    private func mergeUIState() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        
        vm.mergeImapUIStateToImapState()
    }

    @IBAction private func showFilterOptions() {
        performSegue(withIdentifier: .segueShowFilter, sender: self)
    }

    @IBAction private func cancelToolbar() {
        showStandardToolbar()
        lastSelectedIndexPath = nil
        tableView.setEditing(false, animated: true)
        updateBackButton(isTableViewEditing: tableView.isEditing)
    }

    private func change(_ rows: [Int], callback: (EmailListViewCell) -> ()) {
        rows.forEach { (row) in
            let ip = IndexPath(row: row, section: 0)
            if let cell = tableView.cellForRow(at: ip) as? EmailListViewCell {
                callback(cell)
            }
        }
        cancelToolbar()
    }

    @IBAction private func flagToolbar() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if let selectedItems = tableView.indexPathsForSelectedRows {
            vm.markAsFlagged(indexPaths: selectedItems, isEditModeEnabled: true)
        }
    }

    public func didMarkAsFlagged(rows: [Int]) {
        change(rows) { (cell) in
            cell.isFlagged = true
        }
    }

    @IBAction private func unflagToolbar() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if let selectedItems = tableView.indexPathsForSelectedRows {
            vm.markAsUnFlagged(indexPaths: selectedItems, isEditModeEnabled: true)
        }
    }

    public func didMarkAsUnflagged(rows : [Int]) {
        change(rows) { (cell) in
            cell.isFlagged = false
        }
    }

    @IBAction private func readToolbar() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if let selectedItems = tableView.indexPathsForSelectedRows {
            vm.markAsRead(indexPaths: selectedItems, isEditModeEnabled: true)
        }
    }

    public func didMarkAsRead(rows: [Int]) {
        change(rows) { (cell) in
            cell.isSeen = true
        }
    }

    @IBAction private func unreadToolbar() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if let selectedItems = tableView.indexPathsForSelectedRows {
            vm.markAsUnread(indexPaths: selectedItems, isEditModeEnabled: true)
        }
    }

    public func didMarkAsUnread(rows: [Int]) {
        change(rows) { (cell) in
            cell.isSeen = false
        }
    }

    @IBAction private func moveToolbar() {
        performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
        cancelToolbar()
    }

    @IBAction private func deleteToolbar() {
        if let vm = viewModel,
            let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            vm.handleUserClickedDestruktiveButton(forRowsAt: selectedIndexPaths)
        }
        cancelToolbar()
    }

    //recover the original toolbar and right button
    private func showStandardToolbar() {
        let flexibleSpace = createFlexibleBarButtonItem()

        enableFilterButton = UIBarButtonItem.getFilterOnOffButton(action: #selector(filterButtonPressed),
                                                                  target: self)
        guard let vm = viewModel, let enableFilterButton = enableFilterButton else {
            Log.shared.errorAndCrash(message: "No VM!")
            return
        }

        if vm.isDraftsPreviewMode {
            // In this case longPressAction is disabled.
            // User cannot display another drafts preview from drafts preview
            let composeBtn = UIBarButtonItem.getComposeButton(tapAction: #selector(showCompose),
                                                              target: self)
            toolbarItems = [flexibleSpace, composeBtn, flexibleSpace]
            navigationItem.rightBarButtonItem = dismissButton
        } else {
            let composeBtn = UIBarButtonItem.getComposeButton(tapAction: #selector(showCompose),
                                                              longPressAction: #selector(draftsPreviewTapped),
                                                              target: self)
            toolbarItems = [enableFilterButton, flexibleSpace, composeBtn, flexibleSpace, settingsBarButton]
            navigationItem.rightBarButtonItem = editButton
        }
    }

    @objc private func showCompose() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        dismissAndPerform {
            if let address = vm.emailAddress {
                UIUtils.showComposeView(from: address)
            } else {
                UIUtils.showComposeView(from: nil)
            }
        }
    }

    @objc private func draftsPreviewTapped(sender: UILongPressGestureRecognizer) {
        // We need to separate state of long press.
        // We have to take an action only once after long press is recognized
        // We block to do any action when sender.state is in different state (.ended)
        if sender.state != .began {
            return
        }
        UIUtils.presentDraftsPreview()
    }

    private func moveSelectionIfNeeded(fromIndexPath: IndexPath, toIndexPath: IndexPath) {
        if lastSelectedIndexPath == fromIndexPath {
            lastSelectedIndexPath = toIndexPath
            resetSelection()
        }
    }

    private func resetSelection() {
        tableView.selectRow(at: lastSelectedIndexPath, animated: false, scrollPosition: .none)
    }

    // MARK: - Action Filter Button
    
    @IBAction private func filterButtonPressed(_ sender: UIBarButtonItem) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("We should have a model here")
            return
        }
        vm.isFilterEnabled = !vm.isFilterEnabled
        if vm.isFilterEnabled {
            let flexibleSpace = createFlexibleBarButtonItem()
            toolbarItems?.insert(textFilterButton, at: 1)
            toolbarItems?.insert(flexibleSpace, at: 1)
        } else {
            showStandardToolbar()
        }
        updateFilterButton()
    }

    private func updateFilterButton() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("We should have a model here")
            return
        }

        textFilterButton.isEnabled = vm.isFilterEnabled
        if textFilterButton.isEnabled {
            enableFilterButton?.image = UIImage(named: "unread-icon-active")
            updateFilterText()
        } else {
            textFilterButton.title = ""
            enableFilterButton?.image = UIImage(named: "unread-icon")
        }
    }
    
    private func updateFilterText() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        textFilterButton.title = vm.filterButtonTitle
    }

    // MARK: - Memory Warning

    override func didReceiveMemoryWarning() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.freeMemory()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension EmailListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }

        let valueToReturn = vm.rowCount
//        if there is no message to show then there is no message selected and also
//        no message selected screen is shown
        if valueToReturn == 0 {
            showNoMessageSelected()
            lastSelectedIndexPath = nil
        }
        return valueToReturn
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: EmailListViewCell.storyboardId,
                                                 for: indexPath)
        if let theCell = cell as? EmailListViewCell {
            theCell.delegate = self
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return UITableViewCell()
            }
            guard let viewModel = vm.viewModel(for: indexPath.row) else {
                return cell
            }
            theCell.configure(for: viewModel)
            configure(cell: theCell, for: traitCollection)
        } else {
            Log.shared.errorAndCrash("dequeued wrong cell")
        }

        //restores selection state for updated or replaced cells.
        if lastSelectedIndexPath == indexPath {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? EmailListViewCell else {
            return
        }
        cell.clear()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        if tableView.isEditing {
            guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
                // Nothing selected ...
                // ... nothing to do.
                return
            }
            vm.handleEditModeSelectionChange(selectedIndexPaths: selectedIndexPaths)
        } else {
            vm.handleDidSelectRow(indexPath: indexPath)
            refreshUIForCellAt(indexPath: indexPath)
        }
        updateBackButton(isTableViewEditing: tableView.isEditing)
    }

    private func refreshUIForCellAt(indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        if let cell = tableView.cellForRow(at: indexPath) as? EmailListViewCell {
            guard let viewModel = vm.viewModel(for: indexPath.row) else {
                Log.shared.errorAndCrash("No MessageVM for indexPath!")
                return
            }
            cell.configure(for: viewModel)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing, let vm = viewModel {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                vm.handleEditModeSelectionChange(selectedIndexPaths: selectedIndexPaths)
            } else {
                vm.handleEditModeSelectionChange(selectedIndexPaths: [])
            }
        }
        updateBackButton(isTableViewEditing: tableView.isEditing)
    }

    // Implemented to get informed about the scrolling position.
    // If the user has scrolled down (almost) to the end, we need to get older emails to display.
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No model.")
            return
        }
        vm.fetchOlderMessagesIfRequired(forIndexPath: indexPath)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // Using a UITableView (not UITableViewController), the default scroll-to-top gesture
        // (tap on status bar) is broken in this view. It ands up with a content offset > (0.0),
        // showing the inactive pull-to-refresh spinner. This is probably caused by our workaround
        // for adding a pull-to-refresh spinner without gliches.
        //To work around the wrong content offset, we intersept the default implementation here and
        // trigger scoll to top ourselfs.
        guard tableView.numberOfRows(inSection: 0) > 0 else {
            // No cells, no scroll to cell. Else we crash.
            // Do nothing.
            return false
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        return false
    }

    // MARK: - Manipulating the (master) bottom toolbar

    /// Our own factory method for creating flexible space bar button items,
    /// tagged so we recognize them later, for easy removal.
    private func createFlexibleBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil,
            action: nil)
        item.tag = flexibleSpaceButtonItemTag
        return item
    }
}

// MARK: - SwipeTableViewCellDelegate

extension EmailListViewController: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("Should have VM")
            return nil
        }

        // Create swipe actions, taking the currently displayed folder into account
        var leftSwipeActions = [SwipeAction]()

        // Delete or Archive
        let destructiveDescriptor = viewModel.getDestructiveDescriptor(forMessageAt: indexPath.row)
        let archiveAction = SwipeAction(style: .destructive,
                        title: destructiveDescriptor.title(forDisplayMode: .titleAndImage)) {
                            [weak self] action, indexPath in
                            guard let me = self else {
                                Log.shared.lostMySelf()
                                return
                            }
                            me.swipeDelete = action
                            me.deleteAction(forCellAt: indexPath)
        }
        configure(action: archiveAction, with: destructiveDescriptor)
        leftSwipeActions.append(archiveAction)

        // Flag
        if let flagDescriptor = viewModel.getFlagDescriptor(forMessageAt: indexPath.row) {
            let flagAction = SwipeAction(style: .default, title: "Flag") {
                [weak self] action, indexPath in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.flagAction(forCellAt: indexPath)
            }
            flagAction.hidesWhenSelected = true
            configure(action: flagAction, with: flagDescriptor)
            leftSwipeActions.append(flagAction)
        }

        // More (reply++)
        if let moreDescriptor = viewModel.getMoreDescriptor(forMessageAt: indexPath.row) {
            // Do not add "more" actions (reply...) to drafts or outbox.
            let moreAction = SwipeAction(style: .default, title: "More") {
                [weak self] action, indexPath in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.moreAction(forCellAt: indexPath)
            }
            moreAction.hidesWhenSelected = true
            configure(action: moreAction, with: moreDescriptor)
            leftSwipeActions.append(moreAction)
        }

        var rightSwipeActions = [SwipeAction]()
        // Read
        if let readActionDescription = viewModel.getReadDescriptor(forMessageAt: indexPath.row) {
            let readAction = SwipeAction(style: .default, title: "Read") {
                [weak self] action, indexPath in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.readAction(forCellAt: indexPath)
            }
            readAction.hidesWhenSelected = true
            configure(action: readAction, with: readActionDescription)
            rightSwipeActions.append(readAction)
        }

        // "orientation == .right" means actions that are shown in the right side.
        // The swipe is to the left. And Viceversa.
        return orientation == .right ? leftSwipeActions : rightSwipeActions
    }

    func tableView(_ tableView: UITableView,
                   editActionsOptionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.transitionStyle = .border
        options.buttonSpacing = 11
        if orientation == .right {
            options.expansionStyle = .destructive(automaticallyDelete: false)
        } else {
            options.expansionStyle = .selection
        }
        return options
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

    // MARK: - Manipulating the (master) bottom toolbar

    /// Our own factory method for creating pEp bar button items,
    /// tagged so we recognize them later, for easy removal.
    private func createPepBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem.getPEPButton(
            action: #selector(showSettingsViewController),
            target: self)
        return item
    }
}

// MARK: - UISearchResultsUpdating, UISearchControllerDelegate

extension EmailListViewController: UISearchResultsUpdating, UISearchControllerDelegate {

    public func updateSearchResults(for searchController: UISearchController) {
        guard
            let vm = viewModel,
            let searchText = searchController.searchBar.text
            else {
                Log.shared.errorAndCrash("VM not found or text nil, which should not happen")
                return
        }
        vm.handleSearchTermChange(newSearchTerm: searchText)
    }

    public func didDismissSearchController(_ searchController: UISearchController) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No chance to remove filter, sorry.")
            return
        }
        vm.handleSearchControllerDidDisappear()
    }
}

// MARK: - EmailListViewModelDelegate

extension EmailListViewController: EmailListViewModelDelegate {

    public func finishEditingMode() {
        deselectAllCells()
        cancelToolbar()
    }

    public func showEditDraftInComposeView() {
        dismissAndPerform { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.showEditDraftComposeView()
        }
    }

    public func showEmail(forCellAt indexPath: IndexPath) {
        guard let indexPath = lastSelectedIndexPath else {
                Log.shared.errorAndCrash("IndexPath problem!")
                return
        }
        performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: indexPath)
    }

    public func reloadData(viewModel: EmailDisplayViewModel) {
        tableView.reloadData()
    }

    public func willReceiveUpdates(viewModel: EmailDisplayViewModel) {
        tableView.beginUpdates()
    }

    public func allUpdatesReceived(viewModel: EmailDisplayViewModel) {
        tableView.endUpdates()
        updateEditButton()
    }

    public func setToolbarItemsEnabledState(to newValue: Bool) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if vm.shouldShowToolbarEditButtons {
            // Never enable those for outbox
            flagToolbarButton?.isEnabled = newValue
            unflagToolbarButton?.isEnabled = newValue
            readToolbarButton?.isEnabled = newValue
            unreadToolbarButton?.isEnabled = newValue
            moveToolbarButton?.isEnabled = newValue
        }
        deleteToolbarButton?.isEnabled = newValue
    }

    public func showUnflagButton(enabled: Bool) {
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

    public func showUnreadButton(enabled: Bool) {
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

    public func select(itemAt indexPath: IndexPath) {
        guard !onlySplitViewMasterIsShown else {
            // We want to follow EmailDetailViewSelection only if it is shown at the same time (if
            // master/EmailList_and_ detail/EmailDetail views are both currently shown).
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        let cell = tableView.cellForRow(at: indexPath)
        guard !(cell?.isSelected ?? false) else {
            // the cell is already selected. Nothing to do
            return
        }

        let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
        if indexPath.row >= numberOfRows {
            Log.shared.errorAndCrash("Selecting out-of-bounds index %d of max %d",
                                     indexPath.row,
                                     numberOfRows - 1)
            return
        }

        // Select the cell shown in DetailView and scroll to it (nicely animated) in case it is
        // currently not visible.
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            Log.shared.errorAndCrash("No visible rows")
            return
        }
        let cellIsAlreadyVisible = visibleIndexPaths.contains(indexPath)
        let scrollPosition: UITableView.ScrollPosition
        if cellIsAlreadyVisible {
            scrollPosition = .none
        } else {
            if let lastIndex = visibleIndexPaths.last {
                let cellIsBelowVisibleRect = indexPath.row > lastIndex.row
                scrollPosition = cellIsBelowVisibleRect ? .bottom : .top
            } else {
                scrollPosition = .top
            }
        }
        tableView.selectRow(at: indexPath,
                            animated: cellIsAlreadyVisible ? false : true,
                            scrollPosition: scrollPosition)
    }

    public func deselect(itemAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    public func emailListViewModel(viewModel: EmailDisplayViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = nil
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    public func emailListViewModel(viewModel: EmailDisplayViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow ?? lastSelectedIndexPath
        if let swipeDelete = self.swipeDelete {
            swipeDelete.fulfill(with: .delete)
            self.swipeDelete = nil
        } else {
            tableView.deleteRows(at: indexPaths, with: .automatic)
        }
        if viewModel.rowCount == 0 {
            showNoMessageSelected()
        }
    }

    public func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didUpdateDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow
        tableView.reloadRows(at: indexPaths, with: .none)
        // In case the cell was selected before reloading, set it selected after reloading too.
        guard let lastSelectedIndexPath = lastSelectedIndexPath, // Nothing selected, nothing to do.
            indexPaths.contains(lastSelectedIndexPath) else { // the reloaded cell(s) where not selected
            return
        }
        indexPaths.forEach {
            if $0 == lastSelectedIndexPath {
                let cell = tableView.cellForRow(at: $0)
                cell?.isSelected = true
            }
        }
    }

    public func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow
        tableView.moveRow(at: atIndexPath, to: toIndexPath)
        moveSelectionIfNeeded(fromIndexPath: atIndexPath, toIndexPath: toIndexPath)
    }
}

// MARK: - ActionSheet

extension EmailListViewController {
    private func showMoreActionSheet(forRowAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        let alertController = UIUtils.actionSheet()
        let cancelAction = createCancelAction()
        let replyAction = createReplyAction()

        let replyAllAction = createReplyAllAction(forRowAt: indexPath)
        let readAction = createReadOrUnReadAction(forRowAt: indexPath)

        let forwardAction = createForwardAction()
        let moveToFolderAction = createMoveToFolderAction()

        alertController.addAction(cancelAction)
        alertController.addAction(replyAction)

        if let theReplyAllAction = replyAllAction {
            alertController.addAction(theReplyAllAction)
        }

        alertController.addAction(forwardAction)
        alertController.addAction(moveToFolderAction)
        alertController.addAction(readAction)

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = tableView
            let cellFrame = tableView.rectForRow(at: indexPath)
            popoverPresentationController.sourceRect = CGRect(x: cellFrame.maxX,
                                                              y: cellFrame.midY,
                                                              width: 0,
                                                              height: 0)
            popoverPresentationController.permittedArrowDirections = [.left]
        }
        present(alertController, animated: true, completion: nil)
    }

    private func createMoveToFolderAction() -> UIAlertAction {
        let title = NSLocalizedString("Move to Folder", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.performSegue(withIdentifier: .segueShowMoveToFolder, sender: me)
        }
    }

    private func createReadOrUnReadAction(forRowAt indexPath: IndexPath) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UIAlertAction()
        }
        let seenState = vm.viewModel(for: indexPath.row)?.isSeen ?? false

        var title = ""
        if seenState {
            title = NSLocalizedString("Mark as unread", comment: "EmailList action title")
        } else {
            title = NSLocalizedString("Mark as Read", comment: "EmailList action title")
        }

        return UIAlertAction(title: title, style: .default) { [weak self] action in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let vm = me.viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return
            }
            guard let cell = me.tableView.cellForRow(at: indexPath) as? EmailListViewCell else {
                Log.shared.errorAndCrash(message: "Cell type is wrong")
                return
            }
            cell.isSeen = !seenState
            if seenState {
                vm.markAsUnread(indexPaths: [indexPath], isEditModeEnabled: false)
            } else {
                vm.markAsRead(indexPaths: [indexPath], isEditModeEnabled: false)
            }
        }
    }

    private func createCancelAction() -> UIAlertAction {
        let title = NSLocalizedString("Cancel", comment: "EmailList action title")
        return  UIAlertAction(title: title, style: .cancel)
    }

    private func createReplyAction() ->  UIAlertAction {
        let title = NSLocalizedString("Reply", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) {
            [weak self] action in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.performSegue(withIdentifier: .segueReply, sender: me)
        }
    }

    private func createReplyAllAction(forRowAt indexPath: IndexPath) ->  UIAlertAction? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return nil
        }
        if vm.isReplyAllPossible(forRowAt: indexPath) {
            let title = NSLocalizedString("Reply All", comment: "EmailList action title")
            return UIAlertAction(title: title, style: .default) {
                [weak self] action in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.performSegue(withIdentifier: .segueReplyAll, sender: me)
            }
        }
        return nil
    }

    private func createForwardAction() -> UIAlertAction {
        let title = NSLocalizedString("Forward", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) {
            [weak self] action in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.performSegue(withIdentifier: .segueForward, sender: me)
        }
    }
}

// MARK: - TableViewCell Actions

extension EmailListViewController {

    private func readAction(forCellAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        guard let row = vm.viewModel(for: indexPath.row) else {
            Log.shared.errorAndCrash("No data for indexPath!")
            return
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        if row.isSeen {
            vm.markAsUnread(indexPaths: [indexPath], isEditModeEnabled: false)
        } else {
            vm.markAsRead(indexPaths: [indexPath], isEditModeEnabled: false)
        }
        updateRowAt(indexPath: indexPath)
    }

    private func flagAction(forCellAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        guard let row = vm.viewModel(for: indexPath.row) else {
            Log.shared.errorAndCrash("No data for indexPath!")
            return
        }

        if row.isFlagged {
            vm.markAsUnFlagged(indexPaths: [indexPath], isEditModeEnabled: false)
        } else {
            vm.markAsFlagged(indexPaths: [indexPath], isEditModeEnabled: false)
        }
        updateRowAt(indexPath: indexPath)
    }

    private func updateRowAt(indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        guard let viewModel = vm.viewModel(for: indexPath.row) else {
            Log.shared.errorAndCrash("No MessageVM for indexPath!")
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? EmailListViewCell else {
            Log.shared.errorAndCrash("No cell for indexPath!")
            return
        }
        cell.configure(for: viewModel)
    }

    private func deleteAction(forCellAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.delete(forIndexPath: indexPath)
        updateEditButton()
    }

    private func moreAction(forCellAt indexPath: IndexPath) {
        showMoreActionSheet(forRowAt: indexPath)
    }
}

// MARK: - Segue handling

extension EmailListViewController {
    /**
     Enables manual account setup to unwind to the unified inbox.
     */
    @IBAction func segueUnwindAfterAccountCreation(segue: UIStoryboardSegue) {
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
        case segueShowFilter
        case segueFolderViews
        case segueShowMoveToFolder
        case segueShowThreadedEmail
        case noSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .segueReply,
             .segueReplyAll,
             .segueForward,
             .segueCompose:
            setupComposeViewController(for: segue)
        case .segueShowEmail:
            guard
                let emailDetailVC = segue.destination as? EmailDetailViewController,
                let indexPath = sender as? IndexPath
                else {
                    Log.shared.errorAndCrash("Missing required data")
                    return
            }
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            emailDetailVC.viewModel = vm.emailDetialViewModel()
            emailDetailVC.firstItemToShow = indexPath
        case .segueShowFilter:
            guard let destiny = segue.destination as? FilterTableViewController else {
                Log.shared.errorAndCrash("Segue issue")
                return
            }
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            destiny.filterDelegate = vm
            destiny.filterEnabled = vm.currentFilter
            destiny.hidesBottomBarWhenPushed = true
        case .segueAddNewAccount:
            guard
                let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? AccountTypeSelectorViewController else {
                    Log.shared.errorAndCrash("Segue issue")
                    return
            }
            vc.loginDelegate = self
            vc.hidesBottomBarWhenPushed = true
        case .segueFolderViews:
            guard segue.destination is FolderTableViewController  else {
                Log.shared.errorAndCrash("Segue issue")
                return
            }
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
                    Log.shared.errorAndCrash("No DVC?")
                    return
            }
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return
            }
            destination.viewModel = vm.getMoveToFolderViewModel(forSelectedMessages: selectedRows)
        default:
            Log.shared.errorAndCrash("Unhandled segue")
        }
    }

    private func setupComposeViewController(for segue: UIStoryboardSegue) {
        let segueId = segueIdentifier(for: segue)
        guard
            let nav = segue.destination as? UINavigationController,
            let composeVc = nav.topViewController as? ComposeViewController,
            let composeMode = composeMode(for: segueId),
            let vm = viewModel else {
                Log.shared.errorAndCrash("composeViewController setup issue")
                return
        }
        
        if segueId != .segueCompose {
            // This is not a simple compose (but reply, forward or such),
            // thus we have to pass the original message.
            guard let indexPath = lastSelectedIndexPath else {
                Log.shared.info("Can happen if the message the user wanted to reply to has been deleted in between performeSeque and here")
                return
            }

            composeVc.viewModel = vm.composeViewModel(forMessageRepresentedByItemAt: indexPath,
                                                      composeMode: composeMode)
        } else {
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

// MARK: - Accessibility

extension EmailListViewController {

    private func configure(cell: EmailListViewCell, for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        let axis : NSLayoutConstraint.Axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        let spacing : CGFloat = contentSize.isAccessibilityCategory ? 10.0 : 5.0
        cell.firstLineStackView.axis = axis
        cell.firstLineStackView.spacing = spacing
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return
            }
            /// Clear the cache and get the correct version of the avatar..
            vm.freeMemory()
            setSeparator()
            tableView.reloadData()
        }
    }
}

// MARK: - [De]Select all cells

extension EmailListViewController {

    private var selectAllBarButton: UIBarButtonItem {
        let selectAllTitle = NSLocalizedString("Select all", comment: "Select all emails")
        let selectAllCellsSelector = #selector(selectAllCells)
        let button = UIBarButtonItem(title: selectAllTitle, style: .plain, target: self, action: selectAllCellsSelector)
        button.accessibilityIdentifier = AccessibilityIdentifier.selectAllButton
        button.isAccessibilityElement = true
        return button
    }

    private var deselectAllBarButton: UIBarButtonItem {
        let deselectAllTitle = NSLocalizedString("Deselect all", comment: "Deselect all emails")
        let deselectAllCellsSelector = #selector(deselectAllCells)
        let button = UIBarButtonItem(title: deselectAllTitle, style: .plain, target: self, action: deselectAllCellsSelector)
        button.accessibilityIdentifier = AccessibilityIdentifier.deselectAllButton
        button.isAccessibilityElement = true
        return button
    }

    private func updateBackButton(isTableViewEditing: Bool) {
        if isTableViewEditing {
            let item : UIBarButtonItem
            guard let numberOfSelectedRows = tableView.indexPathForSelectedRow?.count else {
                //Valid case, there aren't selected rows
                if tableView.numberOfRows(inSection: 0) > 0 {
                    navigationItem.leftBarButtonItems = [selectAllBarButton]
                }
                return
            }
            item = tableView.numberOfRows(inSection: 0) > numberOfSelectedRows ? selectAllBarButton : deselectAllBarButton
            navigationItem.leftBarButtonItems = [item]
        } else {
            navigationItem.leftBarButtonItems = nil
        }
        navigationItem.hidesBackButton = isTableViewEditing
    }

    @objc private func selectAllCells() {
        for row in 0..<tableView.numberOfRows(inSection: 0) {
            tableView.selectRow(at: IndexPath(item: row, section: 0), animated: false, scrollPosition: .none)
        }
        guard let vm = viewModel, let selectedIndexPaths = tableView?.indexPathsForSelectedRows else {
            //Valid case: there are no selected rows because there are no rows to select. Just ignore.
            return
        }
        vm.handleEditModeSelectionChange(selectedIndexPaths: selectedIndexPaths)

        navigationItem.leftBarButtonItems = [deselectAllBarButton]
    }

    @objc private func deselectAllCells() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        for row in 0..<tableView.numberOfRows(inSection: 0) {
            tableView.deselectRow(at: IndexPath(item: row, section: 0), animated: true)
        }
        vm.handleEditModeSelectionChange(selectedIndexPaths: [])
        navigationItem.leftBarButtonItems = [selectAllBarButton]
    }
}

// MARK: - Present Modal View

extension EmailListViewController {

    private func presentComposeViewToEditDraft(composeVM: ComposeViewModel) {
        let storyboard = UIStoryboard(name: Constants.mainStoryboard, bundle: nil)
        guard
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController
                    as? ComposeViewController
            else {
                Log.shared.errorAndCrash("Missing required VCs")
                return
        }
        composeVc.viewModel = composeVM
        let presenterVc = UIApplication.currentlyVisibleViewController()
        presenterVc.present(composeNavigationController, animated: true)
    }
}

extension EmailListViewController {

    private func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(planckSettingsChanged),
                                               name: .planckSettingsChanged,
                                               object: nil)
    }

    private func setSeparator() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            tableView.separatorColor = UIColor.pEpSeparator
        } else {
            tableView.separatorColor = .opaqueSeparator
        }
    }
}

//MARK: - pEp Settings Changed

extension EmailListViewController {

    @objc func planckSettingsChanged() {
        tableView.reloadData()
    }
}
