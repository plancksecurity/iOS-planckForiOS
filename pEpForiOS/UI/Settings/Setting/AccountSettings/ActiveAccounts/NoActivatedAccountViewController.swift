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

    private var viewModel = NoActivatedAccountViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Accounts", comment: "Title View - Accounts")
        navigationController?.setNavigationBarHidden(true, animated: false)
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        UIHelper.variableContentHeight(tableView)
    }
}

extension NoActivatedAccountViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        guard let row = viewModel.items[indexPath.row] as? NoActivatedAccountRowProtocol else {
            Log.shared.errorAndCrash("Can't get row")
            return cell
        }
        switch row.type {
        case .account:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: AccountSettingsSwitchTableViewCell.identifier, for: indexPath) as? AccountSettingsSwitchTableViewCell, let switchRow = row as? NoActivatedAccountViewModel.SwitchRow {
                //MB:-!
//                dequeuedCell.configure(with: row)
                cell = dequeuedCell
            }
        case .addNewAccount:
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: "addAccountCell", for: indexPath) as? AddAccountTableViewCell, let row = row as? NoActivatedAccountViewModel.ActionRow {
                dequeuedCell.configure(row: row)
                cell = dequeuedCell
            }

        }
        return cell
    }

}
