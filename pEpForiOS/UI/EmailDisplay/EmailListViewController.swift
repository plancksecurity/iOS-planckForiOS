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


class EmailListViewController: UITableViewController {
    struct EmailListConfig {
        let appConfig: AppConfig

        let account: Account?

        /** The folder to display, if it exists */
        let folder: Folder?
    }

    var comp = "EmailListViewController"

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

    func isRead(message: Message)-> Bool {
        return message.imapFlags.seen
    }

    func isImportant(message: Message)-> Bool {
        return message.imapFlags.flagged
    }

    override func viewDidLoad() {
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        updateModel()
        super.viewWillAppear(animated)
    }

    @IBAction func mailSentSegue(_ segue: UIStoryboardSegue) {
    }

    @IBAction func backFromComposeWithoutSavingDraftSegue(_ segue: UIStoryboardSegue) {
    }

    @IBAction func backFromComposeSaveDraftSegue(_ segue: UIStoryboardSegue) {
        guard let message = draftMessageToStore else {
            return
        }

        state.isSynching = true
        updateUI()

        message.imapFlags.draft = true

        // TODO: IOS 222: Save as draft
        if let folder = draftMessageToStore?.parent as? Folder {
            if folder.folderType == .drafts {
                message.save()
                return
            }
        }

        guard let account = config.account else {
            return
        }
        
        if let folder = account.folder(ofType: FolderType.drafts) {
            folder.save(message: message)
            return
        }
    }

    func updateModel() {
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
        if let _ = config.folder {
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fol = config.folder {
            return fol.messageCount()
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

    /**
     The message at the given position.
     */
    func messageAt(indexPath: IndexPath) -> Message? {
        if let fol = config.folder {
            return fol.messageByIndex(indexPath.row)
        }
        return nil
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        draftMessageToCompose = nil

        let cell = tableView.cellForRow(at: indexPath)

        if let fol = config.folder {
            if fol.folderType == .drafts {
                draftMessageToCompose = messageAt(indexPath: indexPath)
                performSegue(withIdentifier: segueCompose, sender: cell)
                return
            }
        }

        performSegue(withIdentifier: segueShowEmail, sender: cell)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt
        indexPath: IndexPath)-> [UITableViewRowAction]? {
        let cell = tableView.cellForRow(at: indexPath) as! EmailListViewCell
        if let email = messageAt(indexPath: indexPath) {
            let isFlagAction = createIsFlagAction(message: email, cell: cell)
            let deleteAction = createDeleteAction(cell)
            let isReadAction = createIsReadAction(message: email, cell: cell)
            return [deleteAction,isFlagAction,isReadAction]
        }
        return nil
    }

    // MARK: - Misc

    func configureCell(_ theCell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = theCell as? EmailListViewCell else {
            return
        }
        if let email = messageAt(indexPath: indexPath) {
            if let pEpRating = email.pEpRating {
                let privacyColor = PEPUtil.pEpColorFromRating(pEpRating)
                if let uiColor = UIHelper.textBackgroundUIColorFromPrivacyColor(privacyColor) {
                    cell.backgroundColor = uiColor
                } else {
                    if determinedCellBackgroundColor {
                        cell.backgroundColor = defaultCellBackgroundColor
                    }
                }
            }
            UIHelper.putString(email.from?.displayString, toLabel: cell.senderLabel)
            UIHelper.putString(email.shortMessage, toLabel: cell.subjectLabel)

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

            if let receivedDate = email.received {
                UIHelper.putString(dateFormatter.string(from: receivedDate as Date),
                                   toLabel: cell.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: cell.dateLabel)
            }

            if (isImportant(message: email) && isRead(message: email)) {
                cell.isImportantImage.isHidden = false
                cell.isImportantImage.backgroundColor = UIColor.orange
            }
            else if (isImportant(message: email) && !isRead(message: email)) {
                cell.isImportantImage.isHidden = false
                cell.isImportantImage.backgroundColor = UIColor.blue
                cell.isImportantImage.layer.borderWidth = 2
                cell.isImportantImage.layer.borderColor = UIColor.orange.cgColor
            } else if (!isImportant(message: email) && isRead(message: email)) {
                    cell.isImportantImage.isHidden = true
            } else if (!isImportant(message: email) && !isRead(message: email)) {
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
                draft.imapFlags.seen = true
                config.appConfig.model.save()

                destination.originalMessage = draft
                destination.composeMode = .composeDraft
            }
        } else if segue.identifier == segueShowEmail {
            guard
                let vc = segue.destination as? EmailViewController,
                let cell = sender as? UITableViewCell,
                let indexPath = self.tableView.indexPath(for: cell),
                let email = messageAt(indexPath: indexPath) else {
                    return
            }
            vc.appConfig = config.appConfig
            vc.message = email
        }
    }

    func syncFlagsToServer(message: Message) {
        // TODO: IOS 222: Sync flags back to server
    }

    func createIsFlagAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {
        // preparing the title action to show when user swipe
        var localizedIsFlagTitle = " "
        if (isImportant(message: message)) {
            localizedIsFlagTitle = NSLocalizedString(
                "Unflag",
                comment: "Unflag button title in swipe action on EmailListViewController")
        } else {
            localizedIsFlagTitle = NSLocalizedString(
                "Flag",
                comment: "Flag button title in swipe action on EmailListViewController")
        }

        // preparing action to trigger when user swipe
        let isFlagCompletionHandler: (UITableViewRowAction, IndexPath) -> Void =
            { (action, indexPath) in
                if (self.isImportant(message: message)) {
                    message.imapFlags.flagged = false

                } else {
                    message.imapFlags.flagged = true
                }
                self.syncFlagsToServer(message: message)
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
        let localizedDeleteTitle = NSLocalizedString(
            "Erase",
            comment: "Erase button title in swipe action on EmailListViewController")

        let deleteCompletionHandler: (UITableViewRowAction, IndexPath) -> Void =
            { (action, indexPath) in
                let message = self.messageAt(indexPath: indexPath)
                message?.imapFlags.deleted = true
                self.syncFlagsToServer(message: message!)
        }

        // creating the action
        let deleteAction = UITableViewRowAction(style: .default, title: localizedDeleteTitle,
                                                handler: deleteCompletionHandler)
        return deleteAction
    }

    func createIsReadAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {
        // preparing the title action to show when user swipe
        var localizedisReadTitle = " "
        if (isRead(message: message)) {
            localizedisReadTitle = NSLocalizedString(
                "Unread",
                comment: "Unread button title in swipe action on EmailListViewController")
        } else {
            localizedisReadTitle = NSLocalizedString(
                "Read",
                comment: "Read button title in swipe action on EmailListViewController")
        }

        // creating the action
        let isReadCompletionHandler: (UITableViewRowAction, IndexPath) -> Void =
            { (action, indexPath) in
                if (self.isRead(message: message)) {
                    message.imapFlags.seen = false
                } else {
                    message.imapFlags.seen = true
                }
                self.syncFlagsToServer(message: message)
                self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        let isReadAction = UITableViewRowAction(style: .default, title: localizedisReadTitle,
                                                handler: isReadCompletionHandler)
        isReadAction.backgroundColor = UIColor.blue

        return isReadAction
    }
}
