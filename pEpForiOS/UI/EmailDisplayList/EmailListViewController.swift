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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
        if MiscUtil.isUnitTest() {
            return
        }

        setup()

        // Mark this folder as having been looked at by the user
        updateLastLookAt()

        //setupFoldersBarButton()
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
        if folderToShow != nil {
            model = EmailListViewModel(delegate: self,
                                       messageSyncService: appConfig.messageSyncService,
                                       folderToShow: folderToShow)
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
    }

    private func weCameBackFromAPushedView() -> Bool {
        return model != nil
    }
    
    private func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }
    
    /*private func setupFoldersBarButton() {
        if let size = navigationController?.viewControllers.count, size > 1 {
            hideFoldersNavigationBarButton()
        } else {
            showFoldersNavigationBarButton()
        }
    }*/

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

    private func address(forRowAt indexPath: IndexPath) -> String {
        guard
            let saveModel = model,
            let row = saveModel.row(for: indexPath),
            let folder = folderToShow
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                return ""
        }
        switch folder.folderType {
        case .all: fallthrough
        case .archive: fallthrough
        case .spam: fallthrough
        case .trash: fallthrough
        case .flagged: fallthrough
        case .inbox: fallthrough
        case .normal:
            return row.from
        case .drafts: fallthrough
        case .sent:
            return row.to
        }
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
        cell.addressLabel.text = address(forRowAt: indexPath)
        cell.subjectLabel.text = row.subject
        cell.summaryLabel.text = row.bodyPeek
        cell.isFlagged = row.isFlagged
        cell.isSeen = row.isSeen
        cell.hasAttachment = row.showAttchmentIcon
        cell.dateLabel.text = row.dateText
        // Set image from cache if any
        cell.setContactImage(image: row.senderContactImage)

        let op = BlockOperation() { [weak self] in
            MessageModel.performAndWait {
                // ... and expensive computations in background
                guard let strongSelf = self else {
                    // View is gone, nothing to do.
                    return
                }

                if row.senderContactImage == nil {
                    // image for identity has not been cached yet
                    // Get (and cache) it here in the background ...
                    let senderImage = strongSelf.model?.senderImage(forCellAt: indexPath)
                    
                    // ... and set it on the main queue
                    DispatchQueue.main.async {
                        if senderImage != nil && senderImage != cell.contactImageView.image {
                            cell.contactImageView.image  = senderImage
                        }
                    }
                }
                
                guard let pEpRatingImage = strongSelf.model?.pEpRatingColorImage(forCellAt: indexPath) else {
                    return
                }
                
                // In theory we want to set all data in *one* async call. But as pEpRatingColorImage takes
                // very long, we are setting the sender image seperatelly. //IOS-999: after Engine rewrite and not logging to Engine anymore computing the peprating is way more performant. Try if moving this up in image setting block.
                DispatchQueue.main.async {
                    cell.setPepRatingImage(image: pEpRatingImage)
                }
            }
        }
        queue(operation: op, for: indexPath)
    }

    private func showComposeView() {
        self.performSegue(withIdentifier: SegueIdentifier.segueEditDraft, sender: self)
    }

    private func showEmail(forCellAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.segueShowEmail, sender: self)
        guard let vm = model else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model.")
            return
        }
        vm.markRead(forIndexPath: indexPath)
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
            configure(cell: theCell, for: indexPath)
        } else {
            Log.shared.errorAndCrash(component: #function, errorString: "dequeued wrong cell")
        }

        return cell
    }
    
    // MARK: - SwipeTableViewCellDelegate

    fileprivate func folderIsDraft(_ parentFolder: Folder) -> Bool {
        return parentFolder.folderType != .drafts
    }

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
        options.expansionStyle = .destructive
        options.transitionStyle = .border
        options.buttonSpacing = 11
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
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelOperation(for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPath: IndexPath) {
        Log.shared.info(component: #function, content: "\(model?.rowCount ?? 0)")
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPath: IndexPath) {
        Log.shared.info(component: #function, content: "\(model?.rowCount ?? 0)")
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPath: IndexPath) {
        Log.shared.info(component: #function, content: "\(model?.rowCount ?? 0)")
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    func updateView() {
        loadingBlocked = false
        tableView.dataSource = self
        tableView.reloadData()
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
        }
        present(alertControler, animated: true, completion: nil)
    }
    
    // MARK: Action Sheet Actions

    private func createMoveToFolderAction() -> UIAlertAction {
        let title = NSLocalizedString("Move to Folder", comment: "EmailList action title")
        return UIAlertAction(title: title, style: .default) { (action) in
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
        guard let row = model?.row(for: indexPath) else {
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
        case .segueShowMoveToFolder:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToFolderViewController,
                let indexPath = lastSelectedIndexPath,
                let message = model?.message(representedByRowAt: indexPath)
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                    break
            }
            destination.appConfig = appConfig
            destination.message = message
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
            // thus we have to pass the original meaasge.
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

/**
 Swipe configuration.
 */
enum SwipeActionDescriptor {
    case read, more, flag, trash, archive

    func title(forDisplayMode displayMode: ButtonDisplayMode) -> String? {
        if displayMode == .imageOnly {
            return nil
        }

        switch self {
        case .read:
            return NSLocalizedString("Read", comment: "read button in slide-left menu")
        case .more:
            return NSLocalizedString("More", comment: "more button in slide-left menu")
        case .flag:
            return NSLocalizedString("Flag", comment: "read button in slide-left menu")
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
        case .more: name = "more"
        case .flag: name = "flag"
        case .trash: name = "trash"
        case .archive: name = "trash"
        }

        return UIImage(named: "swipe-" + name)
    }

    var color: UIColor {
        switch self {
        case .read: return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case .more: return #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        case .flag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .trash: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        case .archive: return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        }
    }
}

enum ButtonDisplayMode {
    case titleAndImage, titleOnly, imageOnly
}

enum ButtonStyle {
    case backgroundColor, circular
}
