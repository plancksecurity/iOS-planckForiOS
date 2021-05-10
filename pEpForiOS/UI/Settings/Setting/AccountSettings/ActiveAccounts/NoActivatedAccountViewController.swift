//
//  NoActiveAccountViewController.swift
//  pEp
//
//  Created by Martín Brude on 7/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class NoActivatedAccountViewController: UIViewController {

    public static let storyboardId = "NoActivatedAccountViewController"

    @IBOutlet private weak var tableView: UITableView!

    private lazy var viewModel = NoActivatedAccountViewModel(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Accounts", comment: "Title View - Accounts")
        navigationController?.setNavigationBarHidden(true, animated: false)
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        UIHelper.variableContentHeight(tableView)
        UIHelper.variableCellHeightsTableView(tableView)
        UIHelper.variableSectionHeadersHeightTableView(tableView)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        headerView.title = viewModel.items[section].title.uppercased()
        return headerView
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.items[section].footer
    }
}

extension NoActivatedAccountViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.items[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .account:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: NoActivatedAccountSwitchCell.identifier, for: indexPath) as? NoActivatedAccountSwitchCell, let switchRow = row as? NoActivatedAccountViewModel.SwitchRow {
                dequeuedCell.configure(with: switchRow)
                return dequeuedCell
            }
        case .addNewAccount:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: "addAccountCell", for: indexPath) as? AddAccountTableViewCell, let row = row as? NoActivatedAccountViewModel.ActionRow {
                dequeuedCell.configure(row: row)
                return dequeuedCell
            }
        }
        Log.shared.errorAndCrash("Can't dequeue cell")
        return UITableViewCell()
    }
}

//MARK: - NoActivatedAccountDelegate

extension NoActivatedAccountViewController: NoActivatedAccountDelegate {

    func dismissYourself() {
        dismiss(animated: true)
    }

    func showAccountSetupView() {
        let accountCreationStoryboard = UIStoryboard(name: Constants.accountCreationStoryboard, bundle: nil)
        guard
            let navigationController = accountCreationStoryboard.instantiateViewController(withIdentifier: Constants.accountCreationNavigation) as? UINavigationController
        else {
            Log.shared.errorAndCrash("Problem!")
            return
        }
        print(navigationController)

    }
}
