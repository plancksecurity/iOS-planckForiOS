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

    var appConfig: AppConfig?
    var fetchController: NSFetchedResultsController?
    var state = UIState()

    override func viewDidLoad() {
        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refresh(_:)),
                                    forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshController
    }

    override func viewWillAppear(animated: Bool) {
        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }
        prepareFetchRequest()

        let account:IAccount? = appConfig!.model.fetchLastAccount()
        if (account == nil)  {
            self.performSegueWithIdentifier("userSettings", sender: self)
        } else {
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
            appConfig!.grandOperator.prefetchEmails(
                connectInfo, folder: ImapSync.defaultImapInboxName, completionBlock: {
                    [unowned self] error in
                    GCD.onMain({
                        Log.info(self.comp, "Sync completed, error: \(error)")
                        self.state.isSynching = false
                        refreshControl?.endRefreshing()
                        self.updateUI()
                    })
                })
            updateUI()
        }
    }

    @IBAction func newAccountCreatedSegue(segue: UIStoryboardSegue) {
        fetchMailsRefreshControl()
    }

    func prepareFetchRequest() {
        let predicates: [NSPredicate] = [NSPredicate.init(format: "bodyFetched = true")]
        let fetchRequest = NSFetchRequest.init(entityName: Message.entityName())
        fetchRequest.predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "originationDate",
            ascending: false)]
        fetchController = NSFetchedResultsController.init(
            fetchRequest: fetchRequest,
            managedObjectContext: appConfig!.coreDataUtil.managedObjectContext,
            sectionNameKeyPath: nil, cacheName: nil)
        fetchController?.delegate = self
        do {
            try fetchController?.performFetch()
        } catch let err as NSError {
            Log.error(comp, error: err)
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
        configureCell(cell, indexPath: indexPath)
        return cell
    }

    func putString(string: String?, toLabel: UILabel) {
        if string?.characters.count > 0 {
            toLabel.hidden = false
            toLabel.text = string!
        } else {
            toLabel.hidden = true
        }
    }

    func configureCell(cell: EmailListViewCell, indexPath: NSIndexPath) {
        if let email = fetchController?.objectAtIndexPath(indexPath) as? Message {
            putString(email.from?.displayString(), toLabel: cell.senderLabel)
            putString(email.subject, toLabel: cell.subjectLabel)
            putString(nil, toLabel: cell.summaryLabel)

            if let originationDate = email.originationDate {
                let formatter = NSDateFormatter.init()
                formatter.dateStyle = .ShortStyle
                formatter.timeStyle = .ShortStyle
                putString(formatter.stringFromDate(originationDate), toLabel: cell.dateLabel)
            } else {
                putString(nil, toLabel: cell.dateLabel)
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "composeSegue" {
            let destination = segue.destinationViewController as! ComposeViewController
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
            Log.info(comp, "unhandled changeSectionType: \(type)")
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
                Log.warn(comp, "Could not find cell for changed indexPath: \(indexPath!)")
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
}