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

//IOS-1250:
/*
 //TODO:
 - Handle now saved setting in decrypt or wherever trusted server plays a role
 - Test!
 */

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
        cell.onOfSwitch.setOn(row.trusted, animated: false)

        return cell
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
        viewModel.setTrusted(forAccountWith: address , toValue: newValue)
    }
}
