//
//  TrustedServerSettingsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 17.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

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
        return NSLocalizedString(
            "If disabled, an unencrypted copy of each message is stored on the server.\n\nDo not disable if you are not sure what you are doing!",
            comment: "Trusted Server Setting Section Footer")
    }
}

// MARK: - TrustedServerSettingCellDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingCellDelegate {
    func trustedServerSettingCell(sender: TrustedServerSettingCell,
                                  didChangeSwitchValue newValue: Bool) {
        guard let address = sender.address.text else {
            Log.shared.errorAndCrash("No address.")
            return
        }
        viewModel.handleStoreSecurely(forAccountWith: address, toValue: newValue)
    }
}

// MARK: - TrustedServerSettingsViewModelDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingsViewModelDelegate {
    func showAlertBeforeStoringSecurely(forAccountWith address: String) {
        guard let storingSecurelyAlert = storingSecurelyAlert(forAccountWith: address) else {
            Log.shared.errorAndCrash("Fail to init storingSecurely pEpAlert")
            //If fail to init the alert, we just skip the alert and store it securely
            viewModel.setStoreSecurely(forAccountWith: address, toValue: true)
            return
        }
        prese
    }
}

// MARK: - Private

extension TrustedServerSettingsViewController {
    private func storingSecurelyAlert(forAccountWith address: String) -> PEPAlertViewController? {
        let title = NSLocalizedString("Security Alert",
                                      comment: "Alert title before trusting an account")
        let message = NSLocalizedString("This is a public cloud account. Your data will be exposed. Are you sure you want to configure this as trusted?",
                                        comment: "Alert message before trusting an account")

        let pepAlert = PEPAlertViewController.fromStoryboard(title: title, message: message)

        let cancelActionTitle = NSLocalizedString("Cancel",
                                                  comment: "Alert cancel button title before trusting an account")
        let cancelAction = PEPUIAlertAction(title: cancelActionTitle,
                                                 style: .pEpBlue,
                                                 handler: { [weak self] _ in
                                                    guard let me = self else {
                                                        Log.shared.lostMySelf()
                                                        return
                                                    }
                                                    me.viewModel.setStoreSecurely(forAccountWith: address, toValue: true)
        })

        let trustActionTitle = NSLocalizedString("Trust",
                                                   comment: "Alert trust button title before trusting an account")
        let trustAction = PEPUIAlertAction(title: trustActionTitle,
                                                   style: .pEpRed,
                                                   handler: { [weak self] _ in
                                                    guard let me = self else {
                                                        Log.shared.lostMySelf()
                                                        return
                                                    }
                                                    me.viewModel.setStoreSecurely(forAccountWith: address, toValue: true)
        })
        pepAlert?.add(action: cancelAction)
        pepAlert?.add(action: trustAction)

        return pepAlert
    }
}
