//
//  FetchTableViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
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


/**
 You can use this as the base for table view controllers based on NSFetchedResultsController.
 */
open class FetchTableViewController: UITableViewController {
    /** Override this in your class */
    var comp: String = "FetchTableViewController"
    var fetchController: NSFetchedResultsController<AnyObject>?

    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        fatalError("implement configureCell(cell:indexPath:)")
    }

    // MARK: - UITableViewDataSource

    override open func numberOfSections(in tableView: UITableView) -> Int {
        if let count = fetchController?.sections?.count {
            return count
        } else {
            return 0
        }
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchController?.sections?.count > 0 {
            if let sections = fetchController?.sections {
                let sectionInfo = sections[section]
                return sectionInfo.numberOfObjects
            }
        }
        return 0
    }
}

extension FetchTableViewController: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int,
                         for type: NSFetchedResultsChangeType) {
        switch (type) {
        case .insert:
            tableView.insertSections(IndexSet.init(integer: sectionIndex),
                                     with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet.init(integer: sectionIndex),
                                     with: .fade)
        default:
            Log.infoComponent(comp, "unhandled changeSectionType: \(type)")
        }
    }

    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
                        at indexPath: IndexPath?,
                                    for type: NSFetchedResultsChangeType,
                                                  newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) {
                self.configureCell(cell, indexPath: indexPath!)
            } else {
                Log.warnComponent(comp, "Could not find cell for changed indexPath: \(indexPath!)")
            }
        case .move:
            if newIndexPath != indexPath {
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            }
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
