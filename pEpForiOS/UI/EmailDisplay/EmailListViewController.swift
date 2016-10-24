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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class EmailListViewController: FetchTableViewController {
    struct EmailListConfig {
        let appConfig: AppConfig

        /** Set to whatever criteria you want to have mails displayed */
        let predicate: NSPredicate?

        /** The sort descriptors to be used for displaying emails */
        let sortDescriptors: [NSSortDescriptor]?

        /** If applicable, the account to refresh from */
        let account: Account?

        /** If applicable, the folder name to sync */
        let folderName: String?

        /** Should there be a sync directly when the view appears? */
        let syncOnAppear: Bool
    }

    struct UIState {
        var isSynching: Bool = false
    }
    
    let segueShowEmail = "segueShowEmail"
    let segueCompose = "segueCompose"
    let segueUserSettings = "segueUserSettings"

    var config: EmailListConfig!

    var state = UIState()
    let dateFormatter = UIHelper.dateFormatterEmailList()

    /**
     The default background color for an email cell, as determined the first time a cell is
     created.
     */
    var defaultCellBackgroundColor: UIColor?

    /**
     Indicates whether `defaultCellBackgroundColor` has been determined or not.
     */
    var determinedCellBackgroundColor: Bool = false

    var refreshController: UIRefreshControl!

    /**
     The message that should be saved as a draft when compose gets aborted.
     */
    var draftMessageToStore: Message?

    /**
     When the user taps on a draft email, this is the message that was selected
     and should be given to the compose view.
     */
    var draftMessageToCompose: Message?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.comp = "EmailListViewController"
    }

    func isReadedMessage(_ message: CdMessage)-> Bool {
        return message.flagSeen.boolValue
    }

    func isImportantMessage(_ message: CdMessage)-> Bool {
        return message.flagFlagged.boolValue
    }

    override func viewDidLoad() {
        refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.fetchMailsRefreshControl(_:)),
                                    for: UIControlEvents.valueChanged)
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        // Disable fetching if there is no account
        if config.account != nil {
            self.refreshControl = refreshController
        } else {
            self.refreshControl = nil
        }

        prepareFetchRequest()
        if config.syncOnAppear {
            fetchMailsRefreshControl()
        }
        super.viewWillAppear(animated)
    }

    func fetchMailsRefreshControl(_ refreshControl: UIRefreshControl? = nil) {
        if let account = config.account, let connectInfo = account.connectInfo {
            state.isSynching = true
            updateUI()

            config.appConfig.grandOperator.fetchEmailsAndDecryptImapSmtp(connectInfos: 
                [connectInfo], folderName: config.folderName,
                completionBlock: { error in
                    Log.infoComponent(self.comp, "Sync completed, error: \(error)")
                    UIHelper.displayError(error, controller: self)
                    self.config.appConfig.model.save()
                    self.state.isSynching = false
                    refreshControl?.endRefreshing()
                    self.updateUI()
            })
        } else {
            state.isSynching = false
            updateUI()
        }
    }

    @IBAction func mailSentSegue(_ segue: UIStoryboardSegue) {
    }

    @IBAction func backFromComposeWithoutSavingDraftSegue(_ segue: UIStoryboardSegue) {
    }

    @IBAction func backFromComposeSaveDraftSegue(_ segue: UIStoryboardSegue) {
        guard let msg = draftMessageToStore else {
            return
        }

        state.isSynching = true
        updateUI()

        config.appConfig.grandOperator.saveDraftMail(
            msg, account: msg.folder.account, completionBlock: { error in
                GCD.onMain() {
                    UIHelper.displayError(error, controller: self)
                    self.state.isSynching = false
                    self.updateUI()
                }
        })
    }

    func prepareFetchRequest() {
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CdMessage.entityName())
        fetchRequest.predicate = config.predicate
        fetchRequest.sortDescriptors = config.sortDescriptors
        fetchController = NSFetchedResultsController.init(
            fetchRequest: fetchRequest,
            managedObjectContext: config.appConfig.coreDataUtil.managedObjectContext,
            sectionNameKeyPath: nil, cacheName: nil)
        fetchController?.delegate = self
        do {
            try fetchController?.performFetch()
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
    }

    // MARK: - UI State

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
        if !state.isSynching {
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let count = fetchController?.sections?.count {
            return count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchController?.sections?.count > 0 {
            if let sections = fetchController?.sections {
                let sectionInfo = sections[section]
                return sectionInfo.numberOfObjects
            }
        }
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EmailListViewCell", for: indexPath) as! EmailListViewCell
        if !determinedCellBackgroundColor {
            defaultCellBackgroundColor = cell.backgroundColor
            determinedCellBackgroundColor = true
        }
        configureCell(cell, indexPath: indexPath)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        draftMessageToCompose = nil

        let cell = tableView.cellForRow(at: indexPath)

        if let fn = config.folderName, let ac = config.account,
            let folder = config.appConfig.model.folderByName(fn, email: ac.user.address) {
            if folder.folderType.intValue == FolderType.drafts.rawValue {
                draftMessageToCompose = fetchController?.object(at: indexPath)
                    as? CdMessage
                performSegue(withIdentifier: segueCompose, sender: cell)
                return
            }
        }

        performSegue(withIdentifier: segueShowEmail, sender: cell)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt
        indexPath: IndexPath)-> [UITableViewRowAction]? {

        let cell = tableView.cellForRow(at: indexPath) as! EmailListViewCell
        let email = fetchController?.object(at: indexPath) as! CdMessage

        let isFlagAction = createIsFlagAction(email, cell: cell)
        let deleteAction = createDeleteAction(cell)
        let isReadAction = createIsReadAction(email, cell: cell)
        return [deleteAction,isFlagAction,isReadAction]
    }

    // MARK: - Misc

    override func configureCell(_ theCell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = theCell as? EmailListViewCell else {
            return
        }
        if let email = fetchController?.object(at: indexPath) as? CdMessage {
            if let colorRating = PEPUtil.pEpRatingFromInt(email.pepColorRating?.intValue) {
                let privacyColor = PEPUtil.pEpColorFromRating(colorRating)
                if let uiColor = UIHelper.textBackgroundUIColorFromPrivacyColor(privacyColor) {
                    cell.backgroundColor = uiColor
                } else {
                    if determinedCellBackgroundColor {
                        cell.backgroundColor = defaultCellBackgroundColor
                    }
                }
            }
            UIHelper.putString(email.from?.displayString(), toLabel: cell.senderLabel)
            UIHelper.putString(email.subject, toLabel: cell.subjectLabel)

            // Snippet
            if let text = email.longMessage {
                let theText = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
                UIHelper.putString(theText, toLabel: cell.summaryLabel)
            } else if let html = email.longMessageFormatted {
                var text = html.extractTextFromHTML()
                text = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
                UIHelper.putString(text, toLabel: cell.summaryLabel)
            } else {
                UIHelper.putString(nil, toLabel: cell.summaryLabel)
            }

            if let receivedDate = email.receivedDate {
                UIHelper.putString(dateFormatter.string(from: receivedDate as Date),
                                   toLabel: cell.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: cell.dateLabel)
            }

            if (isImportantMessage(email) && isReadedMessage(email)) {
                cell.isImportantImage.isHidden = false
                cell.isImportantImage.backgroundColor = UIColor.orange
            }
            else if (isImportantMessage(email) && !isReadedMessage(email)) {
                cell.isImportantImage.isHidden = false
                cell.isImportantImage.backgroundColor = UIColor.blue
                cell.isImportantImage.layer.borderWidth = 2
                cell.isImportantImage.layer.borderColor = UIColor.orange.cgColor
            } else if (!isImportantMessage(email) && isReadedMessage(email)) {
                    cell.isImportantImage.isHidden = true
            } else if (!isImportantMessage(email) && !isReadedMessage(email)) {
                cell.isImportantImage.isHidden = false
                cell.isImportantImage.backgroundColor = UIColor.blue
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Make sure the current account is set, if defined
        config.appConfig.currentAccount = config.account

        if segue.identifier == segueCompose {
            let destination = segue.destination
                as! ComposeViewController
            destination.appConfig = config.appConfig
            if let draft = draftMessageToCompose {
                draft.flagSeen = true
                draft.updateFlags()
                config.appConfig.model.save()

                destination.originalMessage = draft
                destination.composeMode = .composeDraft
            }
        } else if segue.identifier == segueShowEmail {
            guard
                let vc = segue.destination as? EmailViewController,
                let cell = sender as? UITableViewCell,
                let indexPath = self.tableView.indexPath(for: cell),
                let email = fetchController?.object(at: indexPath) as? CdMessage else {
                    return
            }
            vc.appConfig = config.appConfig
            vc.message = email
        }
    }

    func syncFlagsToServer(_ message: CdMessage) {
        self.config.appConfig.grandOperator.syncFlagsToServerForFolder(
            message.folder,
            completionBlock: { error in
                UIHelper.displayError(error, controller: self)
        })
    }

    func createIsFlagAction(_ message: CdMessage, cell: EmailListViewCell) -> UITableViewRowAction {

        // preparing the title action to show when user swipe
        var localizedIsFlagTitle = " "
        if (isImportantMessage(message)) {
            localizedIsFlagTitle = NSLocalizedString("Unflag",
                                                     comment: "Unflag button title in swipe action on EmailListViewController")
        } else {
            localizedIsFlagTitle = NSLocalizedString("Flag",
                                                     comment: "Flag button title in swipe action on EmailListViewController")
        }

        // preparing action to trigger when user swipe
        let isFlagCompletionHandler: (UITableViewRowAction, IndexPath) -> Void =
            { (action, indexPath) in
                if (self.isImportantMessage(message)) {
                    message.flagFlagged = false

                } else {
                    message.flagFlagged = true
                }
                message.updateFlags()
                self.syncFlagsToServer(message)
                self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        // creating the action
        let isFlagAction = UITableViewRowAction(style: .default, title: localizedIsFlagTitle,
                                                handler: isFlagCompletionHandler)
        // changing default action color
        isFlagAction.backgroundColor = UIColor.orange

        return isFlagAction
    }

    func createDeleteAction (_ cell: EmailListViewCell) -> UITableViewRowAction {

        // preparing the title action to show when user swipe
        let localizedDeleteTitle = NSLocalizedString("Erase",
                                                     comment: "Erase button title in swipe action on EmailListViewController")

        let deleteCompletionHandler: (UITableViewRowAction, IndexPath) -> Void =
            { (action, indexPath) in
                let managedObject = self.fetchController?.object(at: indexPath) as? CdMessage
                managedObject?.flagDeleted = true
                managedObject?.updateFlags()
                self.syncFlagsToServer(managedObject!)
        }

        // creating the action
        let deleteAction = UITableViewRowAction(style: .default, title: localizedDeleteTitle,
                                                handler: deleteCompletionHandler)
        return deleteAction
    }

    func createIsReadAction (_ message: CdMessage, cell: EmailListViewCell) -> UITableViewRowAction {

        // preparing the title action to show when user swipe
        var localizedisReadTitle = " "
        if (isReadedMessage(message)) {
            localizedisReadTitle = NSLocalizedString("Unread",
                                                     comment: "Unread button title in swipe action on EmailListViewController")
        } else {
            localizedisReadTitle = NSLocalizedString("Read",
                                                     comment: "Read button title in swipe action on EmailListViewController")
        }

        // creating the action
        let isReadCompletionHandler: (UITableViewRowAction, IndexPath) -> Void =
            { (action, indexPath) in
                if (self.isReadedMessage(message)) {
                    message.flagSeen = false
                    message.updateFlags()
                } else {
                    message.flagSeen = true
                    message.updateFlags()
                }
                self.syncFlagsToServer(message)
                self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        let isReadAction = UITableViewRowAction(style: .default, title: localizedisReadTitle,
                                                handler: isReadCompletionHandler)
        isReadAction.backgroundColor = UIColor.blue

        return isReadAction
    }
}
