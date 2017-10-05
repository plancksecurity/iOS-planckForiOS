//
//  EmailListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MessageModel

struct EmailListConfig {
    var appConfig: AppConfig

    /** The folder to display, if it exists */
    var folder: Folder?

    let imageProvider = IdentityImageProvider()
}

class EmailListViewController: BaseTableViewController {
    public static let storyboardId = "EmailListViewController"
    struct UIState {
        var isSynching: Bool = false
    }

    var config: EmailListConfig?
    var viewModel: EmailListViewModel?
    var state = UIState()
    let searchController = UISearchController(searchResultsController: nil)

    /**
     After trustwords have been invoked, this will be the partner identity that
     was either confirmed or mistrusted.
     */
    var partnerIdentity: Identity?

    @IBOutlet weak var enableFilterButton: UIBarButtonItem!
    @IBOutlet weak var textFilterButton: UIBarButtonItem!

    @IBOutlet var showFoldersButton: UIBarButtonItem!

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

        if let vm = viewModel {
            self.textFilterButton.isEnabled = vm.filterEnabled
            updateFilterText()
        } else {
            self.textFilterButton.isEnabled = false
        }

        setDefaultColors()
        setupConfig()
        updateModel()

        // Mark this folder as having been looked at by the user
        if let folder = config?.folder {
            updateLastLookAt(on: folder)
        }
        if viewModel == nil {
            viewModel = EmailListViewModel(config: config, delegate: self)
        }
        MessageModelConfig.messageFolderDelegate = self

        if let size = navigationController?.viewControllers.count, size > 1 {
            self.showFoldersButton.isEnabled = false
        } else {
            self.showFoldersButton.isEnabled = true
        }
    }

    private func updateLastLookAt(on folder: Folder) {
        if folder.isUnified {
            folder.updateLastLookAt()
        } else {
            folder.updateLastLookAtAndSave()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MessageModelConfig.messageFolderDelegate = nil
    }

    func setupConfig() {
        if config == nil {
            config = EmailListConfig(appConfig: appConfig,
                                     folder: Folder.unifiedInbox())
        }

        if Account.all().isEmpty {
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        }

        guard let folder = config?.folder else {
            return
        }
        self.title = realName(of: folder)
    }

    func addSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        tableView.setContentOffset(CGPoint(x: 0.0, y: 40.0), animated: false)
    }

    func updateModel() {
        tableView.reloadData()
    }

    @IBAction func showUnreadButtonTapped(_ sender: UIBarButtonItem) {
        handlefilter()
    }

    func handlefilter() {
        if let vm = viewModel {
            if vm.filterEnabled {
                vm.filterEnabled = false
                handleButtonFilter(enabled: false)
                if config != nil {
                    vm.resetFilters()
                }
            } else {
                vm.filterEnabled = true
                if config != nil {
                    vm.enableFilter()
                }
                handleButtonFilter(enabled: true)
            }
            self.textFilterButton.isEnabled = vm.filterEnabled
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

    func updateFilterText() {
        if let vm = viewModel, let txt = vm.enabledFilters?.text {
            textFilterButton.title = "Filter by: " + txt
        }
    }

    // MARK: - Private

    private func realName(of folder: Folder) -> String? {
        if folder.isUnified {
            return folder.name
        } else {
            return folder.realName
        }
    }

    // MARK: - UI State

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
        if !state.isSynching {
            refreshControl?.endRefreshing()
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let _ = viewModel?.folderToShow {
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let vm = viewModel {
            return vm.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EmailListViewCell", for: indexPath) as! EmailListViewCell
        let _ = cell.configureCell(config: config, indexPath: indexPath, session: session)
        viewModel?.associate(cell: cell, position: indexPath.row)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, editActionsForRowAt
        indexPath: IndexPath)-> [UITableViewRowAction]? {

        let cell = tableView.cellForRow(at: indexPath) as! EmailListViewCell
        if let email = cell.messageAt(indexPath: indexPath, config: config) {
            let flagAction = createFlagAction(message: email, cell: cell)
            let deleteAction = createDeleteAction(message: email, cell: cell)
            let moreAction = createMoreAction(message: email, cell: cell)
            return [deleteAction, flagAction, moreAction]
        }
        return nil
    }

    // MARK: - Misc

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
        func action(action: UITableViewRowAction, indexPath: IndexPath) -> Void {
            guard let message = cell.messageAt(indexPath: indexPath, config: self.config) else {
                return
            }

            message.delete() // mark for deletion/trash
            self.tableView.reloadData()
        }

        let title = NSLocalizedString("Delete", comment: "Message action (on swipe)")
        return createRowAction(
            cell: cell, image: UIImage(named: "swipe-trash"), action: action,
            title: "\n\n\(title)")
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

    // MARK: - Action Sheet

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

    // MARK: - Action Sheet Actions

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

extension EmailListViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        if let vm = viewModel {
            vm.filterContentForSearchText(searchText: searchController.searchBar.text!, clear: false)
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        if let vm = viewModel {
            vm.filterContentForSearchText(clear: true)
        }
    }
}

// MARK: - Navigation

extension EmailListViewController: SegueHandlerType {

    // MARK: - SegueHandlerType

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
        if let cell = senderCell as? EmailListViewCell,
            let indexPath = self.tableView.indexPath(for: cell),
            let message = cell.messageAt(indexPath: indexPath, config: config) {
            return (message, indexPath)
        }
        return nil
    }

    /// Figures out the the appropriate account to use as sender ("from" field) when composing a mail.
    ///
    /// - Parameter vc: viewController to set the origin on
    private func origin() -> Identity? {
        guard let folder = viewModel?.folderToShow else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder shown?")
            return Account.defaultAccount()?.user
        }
        if folder.isUnified {
            //Set compose views sender ("from" field) to the default account.
            return Account.defaultAccount()?.user
        } else {
            //Set compose views sender ("from" field) to the account we are currently viewing emails for
            return folder.account.user
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
            vc.folderShow = viewModel?.folderToShow
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
            destiny.filterDelegate = viewModel
            destiny.inFolder = false
            destiny.filterEnabled = viewModel?.folderToShow?.filter
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
    }

    func didChangeInternal(messageFolder: MessageFolder) {
        if let folder = config?.folder,
            let message = messageFolder as? Message,
            folder.contains(message: message, deletedMessagesAreContained: true) {
            if message.isOriginal {
                // new message has arrived
                if let index = folder.indexOf(message: message) {
                    let ip = IndexPath(row: index, section: 0)
                    Log.info(
                        component: #function,
                        content: "insert message at \(index), \(folder.messageCount()) messages")
                    tableView.insertRows(at: [ip], with: .automatic)
                } else {
                    tableView.reloadData()
                }
            } else if message.isGhost {
                if let vm = viewModel, let cell = vm.cellFor(message: message), let ip = tableView.indexPath(for: cell) {
                    Log.info(
                        component: #function,
                        content: "delete message at \(index), \(folder.messageCount()) messages")
                    tableView.deleteRows(at: [ip], with: .automatic)
                } else {
                    tableView.reloadData()
                }
            } else {
                // other flags than delete must have been changed
                if let vm = viewModel, let cell = vm.cellFor(message: message) {
                    cell.updateFlags(message: message)
                } else {
                    tableView.reloadData()
                }
            }
        }
    }

}

// MARK: - MessageFolderDelegate

extension EmailListViewController: MessageFolderDelegate {
    func didChange(messageFolder: MessageFolder) {
        GCD.onMainWait {
            self.didChangeInternal(messageFolder: messageFolder)
        }
    }
}

extension EmailListViewController: TableViewUpdate {
    func updateView() {
        if let vm = self.viewModel, let filter = vm.folderToShow?.filter, filter.isDefault() {
            vm.filterEnabled = false
            handleButtonFilter(enabled: false)
        }
        self.tableView.reloadData()
    }
}
