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
    var appConfig: AppConfig?

    /** The folder to display, if it exists */
    var folder: Folder?
}

class EmailListViewController: UITableViewController {
    struct UIState {
        var isSynching: Bool = false
    }

    var config: EmailListConfig?
    var state = UIState()
    let searchController = UISearchController(searchResultsController: nil)
    let cellsByMessageID = NSCache<NSString, EmailListViewCell>()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "EmailList.title".localized
        UIHelper.emailListTableHeight(self.tableView)
        addSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if MiscUtil.isUnitTest() {
            return
        }

        initialConfig()
        updateModel()

        MessageModelConfig.messageFolderDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MessageModelConfig.messageFolderDelegate = nil
    }

    func initialConfig() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        if config == nil {
            config = EmailListConfig(appConfig: appDelegate.appConfig, folder: Folder.unifiedInbox())
        }
        if Account.all().isEmpty {
            performSegue(withIdentifier:.segueAddNewAccount, sender: self)
        }
    }

    func addSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        tableView.setContentOffset(CGPoint(x: 0.0, y: 40.0), animated: false)
    }


    @IBAction func showUnreadButtonTapped(_ sender: UIBarButtonItem) {}

    func updateModel() {
        tableView.reloadData()
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
        if let _ = config?.folder {
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fol = config?.folder  {
            return fol.messageCount()
        }
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EmailListViewCell", for: indexPath) as! EmailListViewCell
        if let messageID = cell.configureCell(config: config, indexPath: indexPath) {
            cellsByMessageID.setObject(cell, forKey: messageID as NSString)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let _ = tableView.cellForRow(at: indexPath) as! EmailListViewCell

        if let fol = config?.folder {
            if fol.folderType == .drafts {
                //performSegue(withIdentifier: .segueCompose, sender: cell)
                return
            }
        }
        //performSegue(withIdentifier: .segueShowEmail, sender: cell)
    }

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

        var title = "\n\nFlag".localized
        if message.imapFlags?.flagged ?? true {
            title = "\n\nUnFlag".localized
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
            message.save()
            self.tableView.reloadData()
        }

        return createRowAction(
            cell: cell, image: UIImage(named: "swipe-trash"), action: action,
            title: "\n\nDelete".localized)
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
            "Unread", comment: "Unread button title in swipe action on EmailListViewController")
        if !cell.haveSeen(message: message) {
            title = NSLocalizedString(
                "Read", comment: "Read button title in swipe action on EmailListViewController")
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

        return createRowAction(
            cell: cell, image: UIImage(named: "swipe-more"), action: action,
            title: "\n\nMore".localized)
    }

    // MARK: - Action Sheet

    func showMoreActionSheet(cell: EmailListViewCell) {
        let alertControler = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertControler.view.tintColor = .pEpGreen
        let cancelAction = createCancelAction()
        let replyAction = createReplyAction(cell: cell)
        let replyAllAction = createReplyAllAction(cell: cell)
        let forwardAction = createForwardAction(cell: cell)
        let markAction = createMarkAction()
        alertControler.addAction(cancelAction)
        alertControler.addAction(replyAction)
        alertControler.addAction(replyAllAction)
        alertControler.addAction(forwardAction)
        alertControler.addAction(markAction)
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
            // self.performSegue(withIdentifier: self.segueCompose, sender: cell)
            self.performSegue(withIdentifier: .segueCompose, sender: cell)
        }
    }

    func createReplyAllAction(cell: EmailListViewCell) ->  UIAlertAction {
        return UIAlertAction(title: "Reply All", style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyAll, sender: cell)
        }
    }

    func createForwardAction(cell: EmailListViewCell) -> UIAlertAction {
        return UIAlertAction(title: "Forward", style: .default) { (action) in
            //self.performSegue(withIdentifier: self.segueCompose, sender: cell)
            self.performSegue(withIdentifier: .segueForward, sender: cell)
        }
    }

    func createMarkAction() -> UIAlertAction {
        return UIAlertAction(title: "Mark", style: .default) { (action) in
        }
    }

    // MARK: - Content Search

    func filterContentForSearchText(searchText: String) {

    }

    // MARK: - Actions
    //    @IBAction func unwindToEmailList(for unwindSegue: UIStoryboardSegue) {
    //
    //    }

}

extension EmailListViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
    }
}

// MARK: - Navigation

extension EmailListViewController: SegueHandlerType {

    // MARK: - SegueHandlerType

    enum SegueIdentifier: String {
        case segueAddNewAccount
        case segueEditAccounts
        case segueShowEmail
        case segueCompose
        case segueReplyAll
        case segueForward
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueCompose:
            //let destination = segue.destination as! ComposeTableViewController
            // destination.appConfig = config.appConfig
            //            if let draft = draftMessageToCompose {
            //                draft.imapFlags?.seen = true
            //
            //                destination.originalMessage = draft
            //                destination.composeMode = .draft
            //            }
            break
        case .segueReplyAll:
            if let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let cell = sender as? EmailListViewCell,
                let indexPath = self.tableView.indexPath(for: cell),
                let email = cell.messageAt(indexPath: indexPath, config: config) {
                destination.composeMode = .replyAll
                destination.appConfig = config?.appConfig
                destination.originalMessage = email
            }
            break
        case .segueShowEmail:
            if let vc = segue.destination as? EmailViewController,
                let cell = sender as? EmailListViewCell,
                let indexPath = self.tableView.indexPath(for: cell),
                let email = cell.messageAt(indexPath: indexPath, config: config) {
                vc.appConfig = config?.appConfig
                vc.message = email
            }
            break
        case .segueForward:
            if let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let cell = sender as? EmailListViewCell,
                let indexPath = self.tableView.indexPath(for: cell),
                let email = cell.messageAt(indexPath: indexPath, config: config) {
                destination.composeMode = .forward
                destination.appConfig = config?.appConfig
                destination.originalMessage = email
            }
            break
        default: ()
        }
    }

    func didChangeInternal(messageFolder: MessageFolder) {
        if let folder = config?.folder,
            let message = messageFolder as? Message,
            folder.contains(message: message, deletedMessagesAreContained: true) {
            if let msg = messageFolder as? Message {
                if msg.isOriginal {
                    // new message has arrived
                    if let index = folder.indexOf(message: msg) {
                        let ip = IndexPath(row: index, section: 0)
                        tableView.insertRows(at: [ip], with: .automatic)
                    } else {
                        tableView.reloadData()
                    }
                } else if msg.isGhost {
                    if let cell = cellsByMessageID.object(forKey: msg.uuid as NSString) {
                        if let ip = tableView.indexPath(for: cell) {
                            tableView.deleteRows(at: [ip], with: .automatic)
                        }
                    }
                } else {
                    // other flags than delete must have been changed
                    if let cell = cellsByMessageID.object(forKey: msg.uuid as NSString) {
                        cell.updateFlags(message: message)
                    }
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
