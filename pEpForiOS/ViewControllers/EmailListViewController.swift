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
    let comp = "EmailListViewController"

    var appConfig: AppConfig?
    var fetchController: NSFetchedResultsController?

    override func viewWillAppear(animated: Bool) {
        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }
        prepareFetchRequest()
        super.viewWillAppear(animated)
    }

    func prepareFetchRequest() {
        let predicates: [NSPredicate] = [NSPredicate.init(value: true)]
        let fetchRequest = NSFetchRequest.init(entityName: Message.entityName())
        fetchRequest.predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "sentDate", ascending: false)]
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

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (fetchController?.sections?.count)!
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
        let cell = tableView.dequeueReusableCellWithIdentifier("EmailListViewCell", forIndexPath: indexPath) as! EmailListViewCell
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
        if let ip = indexPath {
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([ip], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([ip], withRowAnimation: .Fade)
            case .Update:
                // TODO: Configure cell
                Log.warn(comp, "TODO")
            case .Move:
                tableView.deleteRowsAtIndexPaths([ip], withRowAnimation: .Fade)
                if let nip = newIndexPath {
                    tableView.insertRowsAtIndexPaths([nip], withRowAnimation: .Fade)
                } else {
                    Log.warn(comp, "didChangeObject without newIndexPath")
                }
            }
        } else {
            Log.warn(comp, "didChangeObject without indexPath")
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}