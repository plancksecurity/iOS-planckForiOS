//
//  TrustedServerSettingsViewController.swift
//  pEp
//
//  Created by Martin Brude on 02/04/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class TrustedServerSettingsViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!
    private var viewModel = TrustedServerSettingsViewModel()
    
    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        viewModel.delegate = self
    }
}

// MARK: -  UITableViewDataSource

extension TrustedServerSettingsViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Store Messages Securely",
                                 comment: "Trusted Server Setting Section Title")
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString(
            "If disabled, an unencrypted copy of each message is stored on the server.\n\nDo not disable if you are not sure what you are doing!",
            comment: "Trusted Server Setting Section Footer")
    }
}

// MARK: - TrustedServerSettingCellDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingCellDelegate {
    func trustedServerSettingCell(sender: TrustedServerSettingCell, didChangeSwitchValue newValue: Bool) {
        guard let indexPath = tableView.indexPath(for: sender) else {
            Log.shared.errorAndCrash("Invalid indexPath for this TrustedServerSettingCell")
            return
        }
        viewModel.handleStoreSecurely(indexPath: indexPath, toValue: newValue)
    }
}

// MARK: - TrustedServerSettingsViewModelDelegate

extension TrustedServerSettingsViewController: TrustedServerSettingsViewModelDelegate {
    func showAlertBeforeStoringSecurely(forIndexPath indexPath: IndexPath) {
        guard let storingSecurelyAlert = storingSecurelyAlert(forIndexPath: indexPath) else {
            Log.shared.errorAndCrash("Fail to init storingSecurely pEpAlert")
            //If fail to init the alert, we just skip the alert and store it securely
            viewModel.setStoreSecurely(indexPath: indexPath, toValue: true)
            return
        }
        present(storingSecurelyAlert, animated: true)
    }
}

// MARK: - Private

extension TrustedServerSettingsViewController {
    private func storingSecurelyAlert(forIndexPath indexPath: IndexPath) -> PEPAlertViewController? {
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
                                                guard let trustCell = me.tableView.cellForRow(at: indexPath) as? TrustedServerSettingCell else {
                                                    Log.shared.errorAndCrash("Fail to get TrustedServerSettingCell")
                                                    return
                                                }
                                                trustCell.onOfSwitch.setOn(false, animated: true)
                                                pepAlert?.dismiss()
        })

        let trustActionTitle = NSLocalizedString("Trust",
                                                 comment: "Alert trust button title before trusting an account")
        let trustAction = PEPUIAlertAction(title: trustActionTitle,
                                           style: .pEpRed,
                                           handler: { [weak self] _ in
                                            guard let me = self else {
                                                Log.shared.lostMySelf()
                                                pepAlert?.dismiss()
                                                return
                                            }
                                            me.viewModel.setStoreSecurely(indexPath: indexPath, toValue: false)
                                            pepAlert?.dismiss()
        })
        pepAlert?.add(action: cancelAction)
        pepAlert?.add(action: trustAction)

        return pepAlert
    }
}
