//
//  AccountSettingsViewController.swift
//  pEp
//
//  Created by Martin Brude on 27/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation
import MessageModel
import pEpIOSToolbox

final class AccountSettingsViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private weak var keySyncSwitch: UISwitch!

    // MARK: - Variables
    private let oauthViewModel = OAuthAuthorizer()

    var viewModel: AccountSettingsViewModel? = nil

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        UIHelper.variableContentHeight(tableView)
        viewModel?.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        oauthViewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
        title = NSLocalizedString("Account", comment: "Account view title")
        navigationController?.navigationController?.setToolbarHidden(true, animated: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let editableAccountSettingsViewController as EditableAccountSettingsViewController:
            guard let account = viewModel?.account else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            editableAccountSettingsViewController.viewModel = EditableAccountSettingsViewModel(account: account, editableAccountSettingsDelegate: self)
        default:
            break
        }
    }
}

//MARK : - UITableViewDelegate

extension AccountSettingsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM.")
            return
        }
        let sections = vm.sections

        let row = sections[indexPath.section].rows[indexPath.row]
        if row.type == .reset {
            handleResetIdentity()
        }
        if row.type == .oauth2Reauth {
            guard let cell = tableView.cellForRow(at: indexPath) as?
                AccountSettingsOAuthTableViewCell else {
                return
            }
            cell.activityIndicator.startAnimating()
            vm.handleOauth2Reauth(onViewController: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK : - UITableViewDataSource

extension AccountSettingsViewController : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let numberOfSections = viewModel?.sections.count else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return 0
        }
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return 0
        }
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         func dequeue<T: UITableViewCell>(with row : AccountSettingsRowProtocol, type : T.Type) -> T {
            guard let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier)
                as? T else {
                    Log.shared.errorAndCrash(message: "Cell can't be dequeued")
                    return T()
            }
            return dequeuedCell
        }

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Without VM there is no table view.")
            return UITableViewCell()
        }
        let row = vm.sections[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .password:
            let dequeuedCell = dequeue(with: row, type: AccountSettingsTableViewCell.self)
            guard let row = row as? AccountSettingsViewModel.DisplayRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.configure(with: row, for: traitCollection)
            return dequeuedCell

        case .name, .email,
             .server, .port, .tranportSecurity, .username:
            let dequeuedCell = dequeue(with: row, type: AccountSettingsTableViewCell.self)
            guard let row = row as? AccountSettingsViewModel.DisplayRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.configure(with: row, for: traitCollection)
            return dequeuedCell
        case .pepSync:
            let dequeuedCell = dequeue(with: row, type: AccountSettingsSwitchTableViewCell.self)
            guard let row = row as? AccountSettingsViewModel.SwitchRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.configure(with: row, isGrayedOut : !vm.isPEPSyncGrayedOut())
            vm.isKeySyncEnabled(errorCallback: { [weak self] (error) in
                guard let me = self else {
                    // Valid case. We might have been dismissed.
                    return
                }
                dequeuedCell.switchItem.isOn = false
                me.showAlert(error: error)
            }) { (value) in
                dequeuedCell.switchItem.isOn = value
            }
            return dequeuedCell
        case .reset:
            let dequeuedCell = dequeue(with: row, type: AccountSettingsDangerousTableViewCell.self)
            guard let row = row as? AccountSettingsViewModel.ActionRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.configure(with: row)
            return dequeuedCell
        case .oauth2Reauth:
            let dequeuedCell = dequeue(with: row, type: AccountSettingsOAuthTableViewCell.self)
            guard let row = row as? AccountSettingsViewModel.DisplayRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.configure(with: row)

            return dequeuedCell
        case .includeInUnified:
            guard let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier)
                as? AccountSettingsSwitchTableViewCell else {
                    Log.shared.errorAndCrash(message: "Cell can't be dequeued")
                    return UITableViewCell()
            }
            guard let row = row as? AccountSettingsViewModel.SwitchRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.configure(with: row)
//            dequeuedCell.delegate = self
            return dequeuedCell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return nil
        }
        headerView.title = sections[section].title.uppercased()
        return headerView
    }
}

//MARK : - ViewModel Delegate

extension AccountSettingsViewController : AccountSettingsViewModelDelegate {
    func setLoadingView(visible: Bool) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.setLoadingView(visible: visible)
    }

    func showAlert(error: Error) {
        UIUtils.show(error: error)
    }

    func undoPEPSyncToggle() {
        keySyncSwitch.setOn(!keySyncSwitch.isOn, animated: true)
    }
}

//MARK : - Identity

extension AccountSettingsViewController {

    /// Shows an alert to warn the user about resetting the identities
    private func handleResetIdentity() {
        let title = NSLocalizedString("Reset", comment: "Account settings confirm to reset identity title alert")
        let message = NSLocalizedString("This action will reset your identity. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")

        guard let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: title,
                                                  message: message,
                                                  paintPEPInTitle: true) else {
                                                    Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
                                                    return
        }
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let cancelAction = PEPUIAlertAction(title: cancelTitle,
                                            style: .pEpGray,
                                            handler: { _ in
                                                pepAlertViewController.dismiss(animated: true,
                                                                               completion: nil)
        })
        pepAlertViewController.add(action: cancelAction)
        let resetTitle = NSLocalizedString("Reset", comment: "Reset account identity button title")
        let resetAction = PEPUIAlertAction(title: resetTitle,
                                           style: .pEpRed,
                                           handler: { [weak self] _ in
                                            pepAlertViewController.dismiss(animated: true, completion: nil)
                                            guard let me = self else {
                                                Log.shared.lostMySelf()
                                                return
                                            }
                                            guard let vm = me.viewModel else {
                                                Log.shared.errorAndCrash(message: "A view model is required")
                                                return
                                            }
                                            vm.handleResetIdentity()
        })
        pepAlertViewController.add(action: resetAction)
        pepAlertViewController.modalPresentationStyle = .overFullScreen
        pepAlertViewController.modalTransitionStyle = .crossDissolve
        present(pepAlertViewController, animated: true)
    }
}

//MARK : - Accessibility

extension AccountSettingsViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
}

// MARK: - OAuthAuthorizerDelegate

extension AccountSettingsViewController: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        guard let sections = viewModel?.sections else {
            Log.shared.errorAndCrash("Without sections there is no table view.")
            return
        }
        let sectionIndex = (sections.firstIndex(where: { $0.type == .account }) ?? 0) as Int
        let rows = sections[sectionIndex].rows
        let rowIndex = (rows.firstIndex(where: { $0.type == .oauth2Reauth }) ?? 0) as Int
        let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
        guard let cell = tableView.cellForRow(at: indexPath) as?
            AccountSettingsOAuthTableViewCell else {
            return
        }
        cell.activityIndicator.stopAnimating()

        if let error = oauth2Error {
            showAlert(error: error)
            return
        }
        guard let token = accessToken else {
            showAlert(error: OAuthAuthorizerError.noToken)
            return
        }
        viewModel?.updateToken(accessToken: token)
    }
}

// MARK: - AccountSettingsSwitchTableViewCellDelegate

//extension AccountSettingsViewController: AccountSettingsSwitchTableViewCellDelegate {
//    func switchValueChanged(of rowType: AccountSettingsViewModel.RowType, to newValue: Bool) {
//        guard let vm = viewModel else {
//            Log.shared.errorAndCrash(message: "A view model is required")
//            return
//        }
//        if rowType == .pepSync {
//            vm.pEpSync(enable: newValue)
//        }
//        if rowType == .includeInUnified {
//            vm.handleSwitchChanged(isIncludedInUnifiedFolders: newValue)
//            guard let folderTableViewController = navigationController?.child(ofType: FolderTableViewController.self) else {
//                Log.shared.errorAndCrash("FolderTableViewController not found in hierarchy")
//                return
//            }
//            folderTableViewController.folderVM?.refreshFolderList()
//        }
//    }
//}

// MARK: - EditableAccountSettingsDelegate

extension AccountSettingsViewController: EditableAccountSettingsDelegate {
    func didChange() {
        /// As the data source of this table view provides the rows generated at the vm initialization,
        /// we re-init the view model in order re-generate those rows.
        /// With the rows having the data up-to-date we reload the table view.
        if let account = viewModel?.account {
            viewModel = AccountSettingsViewModel(account: account)
            tableView.reloadData()
        }
    }
}
