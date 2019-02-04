//
//  SuggestTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpUtilities

/// Suggests a list of Identities that fit to a given sarch string
class SuggestTableViewController: BaseTableViewController {
    static let storyboardId = "SuggestTableViewController"

    var viewModel: SuggestViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }
}

// MARK: - SuggestViewModelDelegate

extension SuggestTableViewController: SuggestViewModelDelegate {
    func suggestViewModelDidResetModel(showResults: Bool) {
        view.isHidden = !showResults
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension SuggestTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel else {
            Logger.frontendLogger.errorAndCrash("No VM")
            return
        }
        viewModel.handleRowSelected(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource

extension SuggestTableViewController {

    public override func tableView(_ tableView: UITableView,
                                   numberOfRowsInSection section: Int) -> Int {
        guard let viewModel = viewModel else {
            Logger.frontendLogger.errorAndCrash("No VM")
            return 0
        }
        return viewModel.numRows
    }

    public override func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let viewModel = viewModel,
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactCell.reuseId,
                                                       for: indexPath)
            as? ContactCell else {
                Logger.frontendLogger.errorAndCrash("Illegal state")
                return UITableViewCell()
        }
        let row = viewModel.row(at: indexPath.row)
        cell.nameLabel.text = row.name
        cell.emailLabel.text = row.email
        return cell
    }
}
