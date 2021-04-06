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
class SuggestTableViewController: UITableViewController {
    static let storyboardId = "SuggestTableViewController"

    var viewModel: SuggestViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactCell.reuseId,
                                                     for: indexPath)
                as? ContactCell else {
                    Log.shared.errorAndCrash("Illegal state")
                    return UITableViewCell()
        }
        setup(cell: cell, withDataFor: indexPath)

        return cell
    }
}

// MARK: - Private

extension SuggestTableViewController {

    private func setup(cell: ContactCell, withDataFor indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let row = vm[indexPath.row] else {
            /// Valid case: the data source changed after the reload was triggered. 
            return
        }
        cell.nameLabel.text = row.name
        cell.emailLabel.text = row.email
        vm.pEpRatingIcon(for: row) { (icon) in
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                guard me.tableView.indexPath(for: cell) == indexPath else {
                    // The cell setup(cell:withDataFor:) has been called for has already been reused
                    // for representing the data of another indepath while computing the icon.
                    // The computed pEpRatingIcon belonds to the data of the indexpath of the cell
                    // before reusing it.
                    // Don't set the wrong 
                    return
                }
                cell.pEpStatusImageView.image = icon
            }
        }
    }
}
