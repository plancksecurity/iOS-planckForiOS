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
    static let storyboardId = "SuggestTableViewController"

    var viewModel: SuggestViewModel? {
        didSet {
            // Make sure we are the delegate, even some some outter force is setting the VM.
            viewModel?.delegate = self
        }
    }

    // MARK: - Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup

    private func setup() {
        if viewModel == nil {
            viewModel = SuggestViewModel()
        }
    }

    // MARK: - API

    public var hasSuggestions: Bool {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return false
        }
        return !viewModel.isEmpty
    }

    public func updateSuggestions(searchString: String) {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return
        }
        viewModel.updateSuggestion(searchString: searchString)
    }
}

// MARK: - SuggestViewModelDelegate

extension SuggestTableViewController: SuggestViewModelDelegate {
    func suggestViewModelDidResetModel() {
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension SuggestTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
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
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
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
                Log.shared.errorAndCrash(component: #function, errorString: "Illegal state")
                return UITableViewCell()
        }
        let row = viewModel.row(at: indexPath.row)
        cell.nameLabel.text = row.name
        cell.emailLabel.text = row.email
        return cell
    }
}
