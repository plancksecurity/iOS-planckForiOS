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

final class EmailListViewController: BaseViewController, SwipeTableViewCellDelegate {
    /// Stuff that must be done once only in viewWillAppear
    private var doOnce: (()-> Void)?
    /// With this tag we recognize our own created flexible space buttons, for easy removal later.
    private let flexibleSpaceButtonItemTag = 77
    /// True if the pEp button on the left/master side should be shown.
    private var shouldShowPepButtonInMasterToolbar = true

    public static let storyboardId = "EmailListViewController"
    static let FILTER_TITLE_MAX_XAR = 20

    @IBOutlet weak var enableFilterButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    var viewModel: EmailListViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    /// This is used to handle the selection row when it recives an update
    /// and also when swipeCellAction is performed to store from which cell the action is done.
    private var lastSelectedIndexPath: IndexPath?

    private let searchController = UISearchController(searchResultsController: nil)

    //swipe acctions types
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor

    private var swipeDelete: SwipeAction? = nil

    private let refreshController = UIRefreshControl()

    var textFilterButton: UIBarButtonItem = UIBarButtonItem(title: "",
                                                            style: .plain,
                                                            target: nil,
                                                            action: nil)

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .all
        navigationController?.navigationBar.prefersLargeTitles = true

        doOnce = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let vm = me.viewModel else {
                Log.shared.errorAndCrash("No VM")
                return
            }

            me.showNoMessageSelected()

            me.updateFilterButtonView()
            vm.startMonitoring() //!!!: UI should not know about startMonitoring
            me.tableView.reloadData()
            me.doOnce = nil
        }
        setup()
        setUpTextFilter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
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
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setup() {
        tableView.separatorInset = .zero
        tableView.delegate = self
        tableView.dataSource = self
        // rm seperator lines for empty view/cells
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelectionDuringEditing = true
        setupSearchBar()

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        if vm.showLoginView {
            showLoginScreen()
            return
        }

        if vm.shouldShowTutorialWizard {
            TutorialWizardViewController.presentTutorialWizard(viewController: self)
            vm.didShowTutorialWizard()
        }

        ///if we are in setup and the folder is unifiedInbox
        ///we have to reload the unifiedInbox to ensure that all the accounts are present.
        if vm.folderToShow is UnifiedInbox {
            viewModel = EmailListViewModel(delegate: self, folderToShow: UnifiedInbox())
        }
        setupRefreshControl()

        title = viewModel?.folderName
        navigationController?.title = title

        let flexibleSpace = createFlexibleBarButtonItem()
        toolbarItems?.append(contentsOf: [flexibleSpace, createPepBarButtonItem()])
    }

    private func setupRefreshControl() {
        refreshController.tintColor = UIColor.pEpGreen
        refreshController.addTarget(self, action: #selector(refreshView(_:)), for: .valueChanged)
        // Apples default UIRefreshControl implementation is buggy when using a UITableView in a
        // UIViewController (instead of a UITableViewController). The UI freaks out while
        // refreshing and after refreshing the UI is messed (refreshControl and search bar above
        // first tableView cell. Adding the refreshControl as subview of UITableView works around
        // this issue without changing the NavigationBar's "show/hide SearchField when scrolling"
        // behaviour. Do NOT use the intended (`tableView.refreshControl`) way to set the refresh
        // controll up! = refreshController
         tableView.addSubview(refreshController)
    }

    private func setUpTextFilter() {
        textFilterButton.isEnabled = false
        textFilterButton.action = #selector(showFilterOptions(_:))
        textFilterButton.target = self

        let fontSize:CGFloat = 10
        let font:UIFont = UIFont.boldSystemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]

        textFilterButton.setTitleTextAttributes(attributes, for: UIControl.State.normal)
        textFilterButton.setTitleTextAttributes(attributes, for: UIControl.State.selected)
    }

    // MARK: - Search Bar

    private func setupSearchBar() {
        if #available(iOS 11.0, *) {
            searchController.isActive = false
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            searchController.delegate = self
            definesPresentationContext = true
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }

    /// Called on pull-to-refresh triggered
    @objc private func refreshView(_ sender: Any) {
        viewModel?.fetchNewMessages() {[weak self] in
            guard let me = self else {
                // Loosing self is a valid case here. The view might have been dismissed.
                return
            }
            // Loosing self is a valid use case here. We might have been dismissed.
            DispatchQueue.main.async {
                // We intentionally do NOT use me.tableView.refreshControl?.endRefreshing() here.
                // See comments in `setupRefreshControl` for details.
                me.refreshController.endRefreshing()
            }
        }
    }
    // MARK: - Other

    private func showEditDraftComposeView() {
        performSegue(withIdentifier: SegueIdentifier.segueEditDraft, sender: self)
    }

    private func showEmail(forCellAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: self)
    }

    private func showNoMessageSelected() {
        showEmptyDetailViewIfApplicable(message: NSLocalizedString(
            "Please choose a message",
            comment: "No messages has been selected for detail view"))
    }

    private func showLoginScreen() {
        performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        return
    }

    // MARK: - Action Edit Button

    private var tempToolbarItems: [UIBarButtonItem]?
    private var editRightButton: UIBarButtonItem?
    private var flagToolbarButton: UIBarButtonItem?
    private var unflagToolbarButton: UIBarButtonItem?
    private var readToolbarButton: UIBarButtonItem?
    private var unreadToolbarButton: UIBarButtonItem?
    private var deleteToolbarButton: UIBarButtonItem?
    private var moveToolbarButton: UIBarButtonItem?

    private func showEditToolbar() {

        tempToolbarItems = toolbarItems

        // Flexible Space separation between the buttons
        let flexibleSpace = createFlexibleBarButtonItem()

        var img = UIImage(named: "icon-flagged")

        flagToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(flagToolbar(_:)))
        flagToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-unflagged")

        unflagToolbarButton = UIBarButtonItem(image: img,
                                              style: UIBarButtonItem.Style.plain,
                                              target: self,
                                              action: #selector(unflagToolbar(_:)))
        unflagToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-read")

        readToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(readToolbar(_:)))
        readToolbarButton?.isEnabled = false

        img = UIImage(named: "icon-unread")

        unreadToolbarButton = UIBarButtonItem(image: img,
                                              style: UIBarButtonItem.Style.plain,
                                              target: self,
                                              action: #selector(unreadToolbar(_:)))
        unreadToolbarButton?.isEnabled = false

        img = UIImage(named: "folders-icon-trash")

        deleteToolbarButton = UIBarButtonItem(image: img,
                                              style: UIBarButtonItem.Style.plain,
                                              target: self,
                                              action: #selector(deleteToolbar(_:)))

        deleteToolbarButton?.isEnabled = false

        img = UIImage(named: "swipe-archive")

        moveToolbarButton = UIBarButtonItem(image: img,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(moveToolbar(_:)))

        moveToolbarButton?.isEnabled = false

        if var newToolbarItems = [flagToolbarButton, flexibleSpace, readToolbarButton,
                                  flexibleSpace, deleteToolbarButton, flexibleSpace,
                                  moveToolbarButton, flexibleSpace] as? [UIBarButtonItem] {
            if shouldShowPepButtonInMasterToolbar {
                newToolbarItems.append(createPepBarButtonItem())
            }
            toolbarItems = newToolbarItems
        }


        //right navigation button to ensure the logic
        let cancel = UIBarButtonItem(title: NSLocalizedString("Cancel",
                                                              comment: "EmailList: Cancel edit mode button title"),
                                     style: UIBarButtonItem.Style.plain,
                                     target: self,
                                     action: #selector(cancelToolbar(_:)))

        editRightButton = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = cancel
    }

    @objc private func showSettingsViewController() {
        UIUtils.presentSettings(appConfig: appConfig)
    }

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        showEditToolbar()
        tableView.setEditing(true, animated: true)
    }

    @IBAction func showFilterOptions(_ sender: UIBarButtonItem!) {
        performSegue(withIdentifier: .segueShowFilter, sender: self)
    }

    @IBAction func cancelToolbar(_ sender:UIBarButtonItem!) {
        showStandardToolbar()
        lastSelectedIndexPath = nil
        tableView.setEditing(false, animated: true)
    }

    @IBAction func flagToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            viewModel?.markAsFlagged(indexPaths: selectedItems)
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
            viewModel?.markAsUnFlagged(indexPaths: selectedItems)
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
            selectedItems.forEach { (ip) in
                if let cell = self.tableView.cellForRow(at: ip) as? EmailListViewCell {
                    cell.isSeen = true
                }
            }
            viewModel?.markAsRead(indexPaths: selectedItems)
        }
        cancelToolbar(sender)
    }

    @IBAction func unreadToolbar(_ sender:UIBarButtonItem!) {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            viewModel?.markAsUnread(indexPaths: selectedItems)
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
        if let vm = viewModel,
            let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            vm.handleUserClickedDestruktiveButton(forRowsAt: selectedIndexPaths)
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

    private func resetSelection() {
        tableView.selectRow(at: lastSelectedIndexPath, animated: false, scrollPosition: .none)
    }

    // MARK: - Action Filter Button
    
    @IBAction func filterButtonHasBeenPressed(_ sender: UIBarButtonItem) {
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
            toolbarItems?.remove(at: 1)
            toolbarItems?.remove(at: 1)
        }
        updateFilterButtonView()
    }

    private func updateFilterButtonView() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("We should have a model here")
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
        if let vm = viewModel {
            var txt = vm.currentFilter.getFilterText()
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

    // MARK: -

    override func didReceiveMemoryWarning() {
        viewModel?.freeMemory()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension EmailListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let valueToReturn = viewModel?.rowCount ?? 0
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

            guard let viewModel = viewModel?.viewModel(for: indexPath.row) else {
                return cell
            }
            theCell.configure(for: viewModel)
        } else {
            Log.shared.errorAndCrash("dequeued wrong cell")
        }

        //restores selection state for updated or replaced cells.
        if lastSelectedIndexPath == indexPath {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if viewModel == nil {
            return nil
        }

        // Create swipe actions, taking the currently displayed folder into account
        var swipeActions = [SwipeAction]()

        guard let model = viewModel else {
            Log.shared.errorAndCrash("Should have VM")
            return nil
        }

        // Delete or Archive
        let destructiveAction = model.getDestructiveAction(forMessageAt: indexPath.row)
        let archiveAction =
            SwipeAction(style: .destructive,
                        title: destructiveAction.title(forDisplayMode: .titleAndImage)) {
                            [weak self] action, indexPath in
                            guard let me = self else {
                                Log.shared.errorAndCrash("Lost MySelf")
                                return
                            }
                            me.swipeDelete = action
                            me.deleteAction(forCellAt: indexPath)

        }
        configure(action: archiveAction, with: destructiveAction)
        swipeActions.append(archiveAction)

        // Flag
        let flagActionDescription = model.getFlagAction(forMessageAt: indexPath.row)
        if let flagActionDescription = flagActionDescription {
            let flagAction = SwipeAction(style: .default, title: "Flag") {
                [weak self] action, indexPath in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
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
                    Log.shared.errorAndCrash("Lost MySelf")
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
            if vm.isSelectable(messageAt: indexPath) {
                lastSelectedIndexPath = indexPath
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                if vm.isEditable(messageAt: indexPath) {
                    showEditDraftComposeView()
                } else {
                    showEmail(forCellAt: indexPath)
                }
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
            }
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
        //To work around the wron content offset, we intersept the default implementation here and
        // trigger scoll to top ourselfs.
        guard tableView.numberOfRows(inSection: 0) > 0 else {
            // No cells, no scroll to cell. Else we crash.
            // Do nothing.
            return false
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        return false
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

    // MARK: - Manipulating the (master) bottom toolbar

    /// Our own factory method for creating pEp bar button items,
    /// tagged so we recognize them later, for easy removal.
    private func createPepBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem.getPEPButton(
            action: #selector(showSettingsViewController),
            target: self)
        return item
    }

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

    /// - Returns: A new array of `UIBarButtonItem`s with trailing flexible whitespace
    /// removed (at least the ones created by our own factory method).
    /// - Parameter barButtonItems: The bar button items to remove from.
    private func trailingFlexibleSpaceRemoved(barButtonItems: [UIBarButtonItem]) -> [UIBarButtonItem] {
        var theItems = barButtonItems
        while true {
            if let lastItem = theItems.last {
                if lastItem.tag == flexibleSpaceButtonItemTag {
                    theItems.removeLast()
                } else {
                    break
                }
            } else {
                break
            }
        }
        return theItems
    }
}

// MARK: - UISearchResultsUpdating, UISearchControllerDelegate

extension EmailListViewController: UISearchResultsUpdating, UISearchControllerDelegate {

    public func updateSearchResults(for searchController: UISearchController) {
        guard
            let vm = viewModel,
            let searchText = searchController.searchBar.text
            else {
                return
        }
        vm.handleSearchTermChange(newSearchTerm: searchText)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No chance to remove filter, sorry.")
            return
        }
        vm.handleSearchControllerDidDisappear()
    }
}

// MARK: - EmailListViewModelDelegate

extension EmailListViewController: EmailListViewModelDelegate {

    func reloadData(viewModel: EmailDisplayViewModel) {
        tableView.reloadData()
    }

    func willReceiveUpdates(viewModel: EmailDisplayViewModel) {
        tableView.beginUpdates()
    }

    func allUpdatesReceived(viewModel: EmailDisplayViewModel) {
        tableView.endUpdates()
    }

    func setToolbarItemsEnabledState(to newValue: Bool) {
        if viewModel?.shouldShowToolbarEditButtons ?? true {
            // Never enable those for outbox
            flagToolbarButton?.isEnabled = newValue
            unflagToolbarButton?.isEnabled = newValue
            readToolbarButton?.isEnabled = newValue
            unreadToolbarButton?.isEnabled = newValue
            moveToolbarButton?.isEnabled = newValue
        }
        deleteToolbarButton?.isEnabled = newValue
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

    func select(itemAt indexPath: IndexPath) {
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
        //        let visibleIndexPaths = tableView.indexPathsForVisibleRows
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

    func emailListViewModel(viewModel: EmailDisplayViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        lastSelectedIndexPath = nil
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
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

    func emailListViewModel(viewModel: EmailDisplayViewModel,
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

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath) {
        lastSelectedIndexPath = tableView.indexPathForSelectedRow
        tableView.moveRow(at: atIndexPath, to: toIndexPath)
        moveSelectionIfNeeded(fromIndexPath: atIndexPath, toIndexPath: toIndexPath)
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
        let readAction = createReadOrUnReadAction(forRowAt: indexPath)

        let forwardAction = createForwardAction()
        let moveToFolderAction = createMoveToFolderAction()

        alertControler.addAction(cancelAction)
        alertControler.addAction(replyAction)

        if let theReplyAllAction = replyAllAction {
            alertControler.addAction(theReplyAllAction)
        }

        alertControler.addAction(forwardAction)
        alertControler.addAction(moveToFolderAction)
        alertControler.addAction(readAction)

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
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            me.performSegue(withIdentifier: .segueShowMoveToFolder, sender: me)
        }
    }

    private func createReadOrUnReadAction(forRowAt indexPath: IndexPath) -> UIAlertAction {
        let seenState = viewModel?.viewModel(for: indexPath.row)?.isSeen ?? false

        var title = ""
        if seenState {
            title = NSLocalizedString("Mark as unread", comment: "EmailList action title")
        } else {
            title = NSLocalizedString("Mark as Read", comment: "EmailList action title")
        }

        return UIAlertAction(title: title, style: .default) { [weak self] action in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            guard let cell = me.tableView.cellForRow(at: indexPath) as? EmailListViewCell else {
                Log.shared.errorAndCrash(message: "Cell type is wrong")
                return
            }
            cell.isSeen = !seenState
            if seenState {
                me.viewModel?.markAsUnread(indexPaths: [indexPath])
            } else {
                me.viewModel?.markAsRead(indexPaths: [indexPath])
            }
        }
    }

    func createCancelAction() -> UIAlertAction {
        let title = NSLocalizedString("Cancel", comment: "EmailList action title")
        return  UIAlertAction(title: title, style: .cancel)
    }

    func createReplyAction() ->  UIAlertAction {
        let title = NSLocalizedString("Reply", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) {
            [weak self] action in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            me.performSegue(withIdentifier: .segueReply, sender: me)
        }
    }

    func createReplyAllAction(forRowAt indexPath: IndexPath) ->  UIAlertAction? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return nil
        }
        if (vm.isReplyAllPossible(forRowAt: indexPath)) {
            let title = NSLocalizedString("Reply All", comment: "EmailList action title")
            return UIAlertAction(title: title, style: .default) {
                [weak self] action in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
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
                Log.shared.errorAndCrash("Lost MySelf")
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
        guard let row = viewModel?.viewModel(for: indexPath.row) else {
            Log.shared.errorAndCrash("No data for indexPath!")
            return
        }
        guard let cell = self.tableView.cellForRow(at: indexPath) as? EmailListViewCell else {
            Log.shared.errorAndCrash("No cell for indexPath!")
            return
        }
        if row.isFlagged {
            viewModel?.markAsUnFlagged(indexPaths: [indexPath])
            cell.isFlagged = false
        } else {
            viewModel?.markAsFlagged(indexPaths: [indexPath])
            cell.isFlagged = true
        }
    }

    func deleteAction(forCellAt indexPath: IndexPath) {
        viewModel?.delete(forIndexPath: indexPath)
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
            guard
                let vc = segue.destination as? EmailDetailViewController,
                let indexPath = lastSelectedIndexPath else {
                    Log.shared.errorAndCrash("Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.viewModel = viewModel?.emailDetialViewModel()
            vc.firstItemToShow = indexPath
        case .segueShowFilter:
            guard let destiny = segue.destination as? FilterTableViewController else {
                Log.shared.errorAndCrash("Segue issue")
                return
            }
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            destiny.appConfig = appConfig
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
            vc.appConfig = appConfig
            vc.loginDelegate = self
            vc.hidesBottomBarWhenPushed = true
            break
        case .segueFolderViews:
            guard let vC = segue.destination as? FolderTableViewController  else {
                Log.shared.errorAndCrash("Segue issue")
                return
            }
            vC.appConfig = appConfig
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
                    Log.shared.errorAndCrash("No DVC?")
                    break
            }

            destination.viewModel
                = viewModel?.getMoveToFolderViewModel(forSelectedMessages: selectedRows)
            destination.appConfig = appConfig
            break
        default:
            Log.shared.errorAndCrash("Unhandled segue")
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
            let vm = viewModel else {
                Log.shared.errorAndCrash("composeViewController setup issue")
                return
        }
        composeVc.appConfig = appConfig

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
