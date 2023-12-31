//
//  SuggestTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

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
        registerForNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        if traitCollection.userInterfaceStyle == .light {
            cell.backgroundColor = .white
            cell.contentView.backgroundColor = .white
        } else {
            cell.backgroundColor = .secondarySystemBackground
            cell.contentView.backgroundColor = .secondarySystemBackground
        }
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
    }
}

// MARK: - Trait Collection

extension SuggestTableViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            if traitCollection.userInterfaceStyle == .dark {
                tableView.visibleCells.forEach({
                    $0.backgroundColor = .secondarySystemBackground
                    $0.contentView.backgroundColor = .secondarySystemBackground
                })
            } else {
                tableView.visibleCells.forEach({
                    $0.backgroundColor = .white
                    $0.contentView.backgroundColor = .white
                })
            }
        }
    }
}

extension SuggestTableViewController {

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardDidHide),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
    }

    @objc
    private func handleKeyboardDidShow(notification: NSNotification) {
        let margin: CGFloat = 74.0
        tableView.contentInset.bottom = keyBoardHeight(notification: notification) + margin
    }

    @objc
    private func handleKeyboardDidHide(notification: NSNotification) {
        tableView.contentInset.bottom = 0.0
    }

    private func keyBoardHeight(notification: NSNotification) -> CGFloat {
        guard let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return 0
        }
        return keyboardSize.height
    }
}
