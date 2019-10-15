//
//  SettingDefaultAccountTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 07.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/// Lets the user choose the mail account used as default,
/// e.g. when composing a mail in unified inbox, the default account is used as "From".
class SettingDefaultAccountTableViewController: BaseTableViewController {
    let storyboardID = "SettingDefaultAccountTableViewController"
    let cellID = "SettingDefaultAccountCell"
    var allAccounts: [Account] {
        return Account.all()
    }

    // MARK: - UITableviewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAccounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let address = allAccounts[indexPath.row].user.address
        cell.textLabel?.text = address
        cell.tintColor = UIColor.pEpGreen
        if let defaultAccountAddress = AppSettings.defaultAccount,
            defaultAccountAddress == address {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Default Account",
                                 comment: "Default Account Setting Section Title")
    }

    // MARK: - UITableviewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAccount = allAccounts[indexPath.row]
        AppSettings.defaultAccount = selectedAccount.user.address
        tableView.reloadData()
    }
}
