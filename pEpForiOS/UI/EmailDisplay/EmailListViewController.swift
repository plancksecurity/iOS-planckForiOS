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

struct UIState {
    var isSynching: Bool = false
}

class EmailListViewController: UITableViewController {
    let comp = "EmailListViewController"

    let segueShowEmail = "segueShowEmail"
    let segueCompose = "segueCompose"
    let segueUserSettings = "segueUserSettings"

    var appConfig: AppConfig!
    var fetchController: NSFetchedResultsController?
    var state = UIState()
    let dateFormatter = UIHelper.dateFormatterEmailList()
    var shouldFetchFolders = true

    /**
     The default background color for an email cell, as determined the first time a cell is
     created.
     */
    var defaultCellBackgroundColor: UIColor?

    /**
     Indicates whether `defaultCellBackgroundColor` has been determined or not.
     */
    var determinedCellBackgroundColor: Bool = false

    override func viewDidLoad() {
        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refresh(_:)),
                                    forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshController
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func viewWillAppear(animated: Bool) {
        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }
        prepareFetchRequest()

        let account:IAccount? = appConfig.model.fetchLastAccount()
        if (account == nil)  {
            self.performSegueWithIdentifier(segueUserSettings, sender: self)
        } else {
            appConfig.currentAccount = account
            PEPUtil.myselfFromAccount(
                account as! Account, block: { identity in
                    Log.infoComponent(self.comp,
                        "myself: \(identity[kPepAddress]) -> \(identity[kPepFingerprint])")
            })
            fetchMailsRefreshControl()

        }
        super.viewWillAppear(animated)
    }

    func refresh(refreshControl: UIRefreshControl) {
        fetchMailsRefreshControl(refreshControl)
    }

    func fetchMailsRefreshControl(refreshControl: UIRefreshControl? = nil) {
        if let account = appConfig?.model.fetchLastAccount() {
            let connectInfo = account.connectInfo

            state.isSynching = true

            appConfig.grandOperator.fetchEmailsAndDecryptConnectInfo(
                connectInfo, folderName: nil, fetchFolders: shouldFetchFolders,
                completionBlock: { error in
                    Log.infoComponent(self.comp, "Sync completed, error: \(error)")
                    self.appConfig?.model.save()
                    self.state.isSynching = false
                    refreshControl?.endRefreshing()
                    self.updateUI()
            })

            shouldFetchFolders = false
            updateUI()
        }
    }

    @IBAction func newAccountCreatedSegue(segue: UIStoryboardSegue) {
        fetchMailsRefreshControl()
    }

    @IBAction func mailSentSegue(segue: UIStoryboardSegue) {
        print("Mail sent!")
    }

    func prepareFetchRequest() {
        let predicateBody = NSPredicate.init(format: "bodyFetched = true")
        let predicateDecrypted = NSPredicate.init(format: "pepColorRating != nil")
        let predicates: [NSPredicate] = [predicateBody, predicateDecrypted]
        let fetchRequest = NSFetchRequest.init(entityName: Message.entityName())
        fetchRequest.predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "receivedDate",
            ascending: false)]
        fetchController = NSFetchedResultsController.init(
            fetchRequest: fetchRequest,
            managedObjectContext: appConfig.coreDataUtil.managedObjectContext,
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
                let privacyColor = PEPUtil.privacyColorFromPepColorRating(colorRating)
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
            /*
            if let text = email.longMessage {
                let theText = text.replaceNewLinesWith(" ")
                UIHelper.putString(theText, toLabel: cell.summaryLabel)
            } else {
 */
            if let html = email.longMessageFormatted {
                var text = html.extractTextFromHTML()
                text = text.replaceNewLinesWith(" ")
                UIHelper.putString(text, toLabel: cell.summaryLabel)
            } else {
                UIHelper.putString(nil, toLabel: cell.summaryLabel)
            }
        //}

            if let receivedDate = email.receivedDate {
                UIHelper.putString(dateFormatter.stringFromDate(receivedDate),
                                   toLabel: cell.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: cell.dateLabel)
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueCompose {
            let destination = segue.destinationViewController
                as! ComposeViewController
            destination.appConfig = appConfig
        } else if segue.identifier == segueShowEmail {
            guard
                let vc = segue.destinationViewController as? EmailViewController,
                let cell = sender as? UITableViewCell,
                let indexPath = self.tableView.indexPathForCell(cell),
                let email = fetchController?.objectAtIndexPath(indexPath) as? Message else {
                    return
            }
            vc.appConfig = appConfig
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

    override func tableView(tableView: UITableView,
                            commitEditingStyle editingStyle: UITableViewCellEditingStyle,
                                               forRowAtIndexPath indexPath: NSIndexPath) {
        // TODO: Delete from the server and managed errors
        if editingStyle == .Delete {
            let managedObject = fetchController?.objectAtIndexPath(indexPath) as? Message
            fetchController?.managedObjectContext.deleteObject(managedObject!)
        }
    }
}