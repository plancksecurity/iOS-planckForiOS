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

class EmailListViewController: UITableViewController {
    struct EmailListConfig {
        let appConfig: AppConfig

        /** Set to whatever criteria you want to have mails displayed */
        let predicate: NSPredicate?

        /** The sort descriptors to be used for displaying emails */
        let sortDescriptors: [NSSortDescriptor]?

        /** If applicable, the account to refresh from */
        let account: IAccount?

        /** If applicable, the folder name to sync */
        let folderName: String?

        /** Should there be a sync directly when the view appears? */
        let syncOnAppear: Bool
    }

    struct UIState {
        var isSynching: Bool = false
    }
    
    let comp = "EmailListViewController"

    let segueShowEmail = "segueShowEmail"
    let segueCompose = "segueCompose"
    let segueUserSettings = "segueUserSettings"

    var config: EmailListConfig!

    var fetchController: NSFetchedResultsController?
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
    var draftMessageToStore: IMessage?

    func isReadedMessage(message: IMessage)-> Bool {
        return message.flagSeen.boolValue
    }

    func isImportantMessage(message: IMessage)-> Bool {
        return message.flagFlagged.boolValue
    }

    override func viewDidLoad() {
        refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.fetchMailsRefreshControl(_:)),
                                    forControlEvents: UIControlEvents.ValueChanged)
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func viewWillAppear(animated: Bool) {
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

    func fetchMailsRefreshControl(refreshControl: UIRefreshControl? = nil) {
        if let account = config.account {
            let connectInfo = account.connectInfo

            state.isSynching = true
            updateUI()

            config.appConfig.grandOperator.fetchEmailsAndDecryptConnectInfos(
                [connectInfo], folderName: config.folderName,
                completionBlock: { error in
                    Log.infoComponent(self.comp, "Sync completed, error: \(error)")
                    if let err = error {
                        UIHelper.displayError(err, controller: self)
                    }
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

    @IBAction func mailSentSegue(segue: UIStoryboardSegue) {
    }

    @IBAction func backFromComposeWithoutSavingDraftSegue(segue: UIStoryboardSegue) {
    }

    @IBAction func backFromComposeSaveDraftSegue(segue: UIStoryboardSegue) {
        // TODO: Save draft
        guard let msg = draftMessageToStore else {
            return
        }
        print("compose aborted, saving draft")
        config.appConfig.grandOperator.saveDraftMail(
            msg, account: msg.folder.account, completionBlock: { error in
        })
    }

    func prepareFetchRequest() {
        let fetchRequest = NSFetchRequest.init(entityName: Message.entityName())
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
        if state.isSynching {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let count = fetchController?.sections?.count {
            return count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchController?.sections?.count > 0 {
            if let sections = fetchController?.sections {
                let sectionInfo = sections[section]
                return sectionInfo.numberOfObjects
            }
        }
        return 0
    }

    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            "EmailListViewCell", forIndexPath: indexPath) as! EmailListViewCell
        if !determinedCellBackgroundColor {
            defaultCellBackgroundColor = cell.backgroundColor
            determinedCellBackgroundColor = true
        }
        configureCell(cell, indexPath: indexPath)
        return cell
    }

    func configureCell(cell: EmailListViewCell, indexPath: NSIndexPath) {
        if let email = fetchController?.objectAtIndexPath(indexPath) as? Message {
            if let colorRating = PEPUtil.colorRatingFromInt(email.pepColorRating?.integerValue) {
                let privacyColor = PEPUtil.colorFromPepRating(colorRating)
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
                UIHelper.putString(dateFormatter.stringFromDate(receivedDate),
                                   toLabel: cell.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: cell.dateLabel)
            }

            if (isImportantMessage(email) && isReadedMessage(email)) {
                cell.isImportantImage.hidden = false
                cell.isImportantImage.backgroundColor = UIColor.orangeColor()
            }
            else if (isImportantMessage(email) && !isReadedMessage(email)) {
                cell.isImportantImage.hidden = false
                cell.isImportantImage.backgroundColor = UIColor.blueColor()
                cell.isImportantImage.layer.borderWidth = 2
                cell.isImportantImage.layer.borderColor = UIColor.orangeColor().CGColor
            } else if (!isImportantMessage(email) && isReadedMessage(email)) {
                    cell.isImportantImage.hidden = true
            } else if (!isImportantMessage(email) && !isReadedMessage(email)) {
                cell.isImportantImage.hidden = false
                cell.isImportantImage.backgroundColor = UIColor.blueColor()
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Make sure the current account is set, if defined
        config.appConfig.currentAccount = config.account

        if segue.identifier == segueCompose {
            let destination = segue.destinationViewController
                as! ComposeViewController
            destination.appConfig = config.appConfig
        } else if segue.identifier == segueShowEmail {
            guard
                let vc = segue.destinationViewController as? EmailViewController,
                let cell = sender as? UITableViewCell,
                let indexPath = self.tableView.indexPathForCell(cell),
                let email = fetchController?.objectAtIndexPath(indexPath) as? Message else {
                    return
            }
            vc.appConfig = config.appConfig
            vc.message = email
        }
    }
}

extension EmailListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController,
                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                     atIndex sectionIndex: Int,
                                             forChangeType type: NSFetchedResultsChangeType) {
        switch (type) {
        case .Insert:
            tableView.insertSections(NSIndexSet.init(index: sectionIndex),
                                     withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet.init(index: sectionIndex),
                                     withRowAnimation: .Fade)
        default:
            Log.infoComponent(comp, "unhandled changeSectionType: \(type)")
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,
                    atIndexPath indexPath: NSIndexPath?,
                                forChangeType type: NSFetchedResultsChangeType,
                                              newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
                self.configureCell(cell as! EmailListViewCell, indexPath: indexPath!)
            } else {
                Log.warnComponent(comp, "Could not find cell for changed indexPath: \(indexPath!)")
            }
        case .Move:
            if newIndexPath != indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

    func syncFlagsToServer(message: IMessage) {
        self.config.appConfig.grandOperator.syncFlagsToServerForFolder(
            message.folder,
            completionBlock: { error in
                if let err = error {
                    UIHelper.displayError(err, controller: self)
                }
        })
    }

    func createIsFlagAction(message: Message, cell: EmailListViewCell) -> UITableViewRowAction {

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
        let isFlagCompletionHandler: (UITableViewRowAction, NSIndexPath) -> Void =
            { (action, indexPath) in
                if (self.isImportantMessage(message)) {
                    message.flagFlagged = false

                } else {
                    message.flagFlagged = true
                }
                message.updateFlags()
                self.syncFlagsToServer(message)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            }
        // creating the action
        let isFlagAction = UITableViewRowAction(style: .Default, title: localizedIsFlagTitle,
                                                handler: isFlagCompletionHandler)
        // changing default action color
        isFlagAction.backgroundColor = UIColor.orangeColor()

        return isFlagAction
    }

    func createDeleteAction (cell: EmailListViewCell) -> UITableViewRowAction {

        // preparing the title action to show when user swipe
        let localizedDeleteTitle = NSLocalizedString("Erase",
        comment: "Erase button title in swipe action on EmailListViewController")

        let deleteCompletionHandler: (UITableViewRowAction, NSIndexPath) -> Void =
            { (action, indexPath) in
                let managedObject = self.fetchController?.objectAtIndexPath(indexPath) as? IMessage
                managedObject?.flagDeleted = true
                managedObject?.updateFlags()
                self.syncFlagsToServer(managedObject!)
            }

        // creating the action
        let deleteAction = UITableViewRowAction(style: .Default, title: localizedDeleteTitle,
                                                handler: deleteCompletionHandler)
        return deleteAction
    }

    func createIsReadAction (message: Message, cell: EmailListViewCell) -> UITableViewRowAction {

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
        let isReadCompletionHandler: (UITableViewRowAction, NSIndexPath) -> Void =
            { (action, indexPath) in
                if (self.isReadedMessage(message)) {
                    message.flagSeen = false
                    message.updateFlags()
                } else {
                    message.flagSeen = true
                    message.updateFlags()
                }
                self.syncFlagsToServer(message)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            }
        let isReadAction = UITableViewRowAction(style: .Default, title: localizedisReadTitle,
                                                handler: isReadCompletionHandler)
        isReadAction.backgroundColor = UIColor.blueColor()

        return isReadAction
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath
                  indexPath: NSIndexPath)-> [UITableViewRowAction]? {

        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EmailListViewCell
        let email = fetchController?.objectAtIndexPath(indexPath) as! Message

        let isFlagAction = createIsFlagAction(email, cell: cell)
        let deleteAction = createDeleteAction(cell)
        let isReadAction = createIsReadAction(email, cell: cell)
        return [deleteAction,isFlagAction,isReadAction]
    }
}