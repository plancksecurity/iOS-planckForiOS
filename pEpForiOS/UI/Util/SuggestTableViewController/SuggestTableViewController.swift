//
//  SuggestTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

/// Suggests a list of Identities that fit to a given sarch string
class SuggestTableViewController: BaseTableViewController {
    static let storyboardId = "SuggestTableViewController"

    var viewModel: SuggestViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
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
            Log.shared.errorAndCrash("No VM")
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
            Log.shared.errorAndCrash("No VM")
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
                    Log.shared.errorAndCrash("Illegal state")
                    return UITableViewCell()
        }
        let row = viewModel[indexPath.row]

        let pEpRating = viewModel.calculatePepRating(toEmailAddress: row.email)
        let pEpRatingIcon = pEpRating.pEpColor().statusIconInContactPicture()
        cell.updateCell(name: row.name,
                        email: row.email,
                        pEpStatusIcon: pEpRatingIcon)

        return cell
    }
}
