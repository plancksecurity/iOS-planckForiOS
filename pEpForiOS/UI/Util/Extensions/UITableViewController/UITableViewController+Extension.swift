//
//  UITableViewController+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 11/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UITableViewController {
    static func setupCommonSettings(tableView: UITableView) {
        hideSeperatorForEmptyCells(on: tableView)
    }
    
    static private func hideSeperatorForEmptyCells(on tableView: UITableView) {
        // Add empty footer to not show empty cells (visible as dangling seperators)
        if tableView.tableFooterView == nil {
            tableView.tableFooterView = UIView(frame: .zero)
        }
    }
}


