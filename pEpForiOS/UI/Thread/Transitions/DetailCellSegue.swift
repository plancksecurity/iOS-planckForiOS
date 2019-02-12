//
//  DetailCellSegue.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 15/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpUtilities

class DetailCellSegue: UIStoryboardSegue {

    override func perform() {
        guard let threadViewController = source as? ThreadViewController,
        let navigationController = destination as? UINavigationController,
        let destinationVC = navigationController.rootViewController,
        let destinationView = destinationVC.view.snapshotView(afterScreenUpdates: true),
        let tableView = threadViewController.tableView,
        let selectedIndexPath = tableView.indexPathForSelectedRow,
        let cell = tableView.cellForRow(at: selectedIndexPath)
        else {
            return
        }


        // create an NSData object from myView
        let archive = NSKeyedArchiver.archivedData(withRootObject: cell.contentView)

        // create a clone by unarchiving the NSData
        let view = NSKeyedUnarchiver.unarchiveObject(with: archive) as! UIView

        let originalFrame = destinationView.frame

        view.frame = threadViewController.view.convert(cell.frame, from: tableView)
        threadViewController.view.insertSubview(view, aboveSubview: tableView)

        UIView.animate(withDuration: 0.4, animations: {
            view.frame = originalFrame

        }) { (completed) in
            threadViewController.showDetailViewController(self.destination, sender: threadViewController)
            view.removeFromSuperview()
        }
    }
}
