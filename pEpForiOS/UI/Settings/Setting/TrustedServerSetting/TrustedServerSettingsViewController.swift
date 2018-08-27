//
//  TrustedServerSettingsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 17.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class TrustedServerSettingsViewController: BaseTableViewController {
    var viewModel = TrustedServerSettingsViewModel()
}

// MARK: -  UITableViewDataSource

extension TrustedServerSettingsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell =
            tableView.dequeueReusableCell(withIdentifier: TrustedServerSettingCell.storyboardId) as?
            TrustedServerSettingCell
            else {
                return UITableViewCell()
        }
        cell.delegate = self
        let row = viewModel.rows[indexPath.row]
        cell.address.text = row.address
        cell.onOfSwitch.setOn(row.storeMessagesSecurely, animated: false)

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Store Messages Securely",
                                 comment: "Trusted Server Setting Section Title")
    }

    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("If disabled, an unencrypted copy of each message is stored on " +
            "the server.\n\nDo not disable if you are not sure what you are doing!",
                                 comment: "Trusted Server Setting Section Footer")
    }
}

// MARK: - TrustedServerSettingCellDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingCellDelegate {
    func trustedServerSettingCell(sender: TrustedServerSettingCell,
                                  didChangeSwitchValue newValue: Bool) {
        guard let address = sender.address.text else {
            Log.shared.errorAndCrash(component: #function, errorString: "No address.")
            return
        }
        viewModel.setStoreSecurely(forAccountWith: address , toValue: newValue)
    }
}
