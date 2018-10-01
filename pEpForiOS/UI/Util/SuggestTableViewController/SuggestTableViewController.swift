//
//  SuggestTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation


/// Suggests a list of Name & EmailAddress pairs for a given search string
class SuggestTableViewController: UITableViewController {
    static let storyboardId = String(describing: self)

    let viewModel = SuggestViewModel()

}

// MARK: - UITableViewDelegate

extension SuggestTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.handleRowSelected(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource

extension SuggestTableViewController {

    public override func tableView(_ tableView: UITableView,
                                   numberOfRowsInSection section: Int) -> Int {
        return viewModel.numRows
    }

    public override func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactCell.reuseId,
                                                       for: indexPath)
            as? ContactCell else {
                return UITableViewCell()
        }
        let row = viewModel.row(at: indexPath.row)
        cell.nameLabel.text = row.name
        cell.emailLabel.text = row.email
        return cell
    }
}
