//
//  SettingsTableViewController.swift
//  pEp
//
//  Created by Martin Brude on 22/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import SwipeCellKit
import pEpIOSToolbox

final class SettingsTableViewController: BaseTableViewController {

    static let storyboardId = "SettingsTableViewController"
    private weak var activityIndicatorView: UIActivityIndicatorView?

    private lazy var viewModel = SettingsViewModel(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        viewModel.delegate = self
        UIHelper.variableCellHeightsTableView(tableView)
        UIHelper.variableSectionHeadersHeightTableView(tableView)
        addExtraKeysEditabilityToggleGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
        showEmptyDetailViewIfApplicable(message: NSLocalizedString("Please choose a setting",
                                                                   comment: "No setting has been selected yet in the settings VC"))
    }

// MARK: - Extra Keys
    /// Adds easter egg gesture to [en|dis]able the editability of extra keys
    private func addExtraKeysEditabilityToggleGesture() {
        let gestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(extraKeysEditabilityToggleGestureTriggered))
        gestureRecogniser.numberOfTapsRequired = 6
        gestureRecogniser.numberOfTouchesRequired = 3
        tableView.addGestureRecognizer(gestureRecogniser)
    }

    /// [en|dis]able the editability of extra keys
    @objc private func extraKeysEditabilityToggleGestureTriggered() {
        viewModel.handleExtraKeysEditabilityGestureTriggered()
    }
}

// MARK: - Private

extension SettingsTableViewController {

    private func setUp() {
        title = NSLocalizedString("Settings", comment: "Settings view title")
        tableView.register(pEpHeaderView.self, forHeaderFooterViewReuseIdentifier: pEpHeaderView.reuseIdentifier)
    }
    /// Prepares and returns the swipe tableview cell, with the corresponding color and title.
    /// - Parameters:
    ///   - dequeuedCell: the cell to configure
    ///   - row: the row with the information to configure the cell
    private func prepareSwipeTableViewCell(_ dequeuedCell: UITableViewCell?, for row: SettingsRowProtocol) -> SwipeTableViewCell {
        guard let cell = dequeuedCell as? SwipeTableViewCell else {
            Log.shared.errorAndCrash("Invalid state.")
            return SwipeTableViewCell()
        }
        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = viewModel.titleColor(rowIdentifier: row.identifier)
        cell.textLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
        cell.detailTextLabel?.text = nil
        cell.delegate = self
        return cell
    }

    /// Prepares and returns the action tableview cell, with the corresponding color and title.
    /// - Parameters:
    ///   - dequeuedCell: the cell to configure
    ///   - row: the row with the information to configure the cell
    private func prepareActionCell(_ dequeuedCell: UITableViewCell, for row: SettingsRowProtocol) -> UITableViewCell {
        dequeuedCell.textLabel?.text = row.title
        dequeuedCell.textLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
        dequeuedCell.textLabel?.textColor = viewModel.titleColor(rowIdentifier: row.identifier)
        dequeuedCell.detailTextLabel?.text = nil
        Appearance.configureSelectedBackgroundViewForPep(tableViewCell: dequeuedCell)
        return dequeuedCell
    }

    /// Prepares and returns the switch tableview cell, with the corresponding color and title.
    /// - Parameters:
    ///   - dequeuedCell: the cell to configure
    ///   - row: the row with the information to configure the cell
    private func prepareSwitchTableViewCell(_ dequeuedCell: UITableViewCell?, for row: SettingsViewModel.SwitchRow) -> SettingSwitchTableViewCell {
        guard let cell = dequeuedCell as? SettingSwitchTableViewCell else {
            Log.shared.errorAndCrash("Invalid state.")
            return SettingSwitchTableViewCell()
        }
        cell.switchDescription.text = row.title
        cell.switchDescription.font = UIFont.pepFont(style: .body, weight: .regular)
        cell.switchDescription.textColor = viewModel.titleColor(rowIdentifier: row.identifier)
        cell.delegate = self
        cell.selectionStyle = .none
        cell.switchItem.setOn(row.isOn, animated: true)
        return cell
    }

    /// Method to get the cell of the table view configured.
    /// - Parameters:
    ///   - tableView: The table view to dequeue the cell
    ///   - indexPath: The indexPath to identify the cell. 55
    private func dequeueCell(for tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cellId = viewModel.cellIdentifier(for: indexPath)
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        Appearance.configureSelectedBackgroundViewForPep(tableViewCell: dequeuedCell)
        let row : SettingsRowProtocol = viewModel.section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .account:
            return prepareSwipeTableViewCell(dequeuedCell, for: row)
        case .resetAccounts, .resetTrust:
            return prepareActionCell(dequeuedCell, for: row)
        case .defaultAccount, .setOwnKey, .credits, .trustedServer, .extraKeys:
            guard let row = row as? SettingsViewModel.NavigationRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.textLabel?.text = row.title
            dequeuedCell.textLabel?.textColor = viewModel.titleColor(rowIdentifier: row.identifier)
            dequeuedCell.textLabel?.font = UIFont.pepFont(style: .body, weight: .regular)

            dequeuedCell.detailTextLabel?.text = row.subtitle
            dequeuedCell.detailTextLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
            return dequeuedCell
        case .passiveMode, .protectMessageSubject, .pEpSync, .unsecureReplyWarningEnabled:
            guard let row = row as? SettingsViewModel.SwitchRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            return prepareSwitchTableViewCell(dequeuedCell, for: row)
        }
    }

    /// Presents an alert controller if the user taps the reset all identity cell.
    private func handleResetAllIdentity(action : @escaping SettingsViewModel.ActionBlock) {
        if let pepAlertViewController = getResetAllIdentityAlertController(action: action) {
            DispatchQueue.main.async { [weak self] in
                self?.present(pepAlertViewController, animated: true)
            }
        }
    }

    /// Shows the alert controller before deleting an account
    /// - Parameter indexPath: The index to delete the row in case of acceptance.
    private func showAlertBeforeDelete(indexPath : IndexPath, action : @escaping SettingsViewModel.ActionBlock) {
        let alertController = getBeforeDeleteAlert(deleteCallback: { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            action()
            me.tableView.beginUpdates()
            me.tableView.deleteRows(at: [indexPath], with: .fade)
            me.tableView.endUpdates()
            me.checkAccounts()
        })
        if let popoverPresentationController = alertController.popoverPresentationController {
            let cellFrame = tableView.rectForRow(at: indexPath)
            let sourceRect = view.convert(cellFrame, from: tableView)
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.sourceView = view
        }
        present(alertController, animated: true)
    }

    private func checkAccounts() {
        if viewModel.noAccounts() {
            performSegue(withIdentifier: "noAccounts", sender: nil)
        }
    }
}

// MARK: - UITableViewDataSource

extension SettingsTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.section(for: section).rows.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: pEpHeaderView.reuseIdentifier) as? pEpHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }

        headerView.title = viewModel.section(for: section).title.uppercased()
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.section(for: section).footer
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dequeueCell(for: tableView, for: indexPath)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }
}

// MARK: - UITableViewDelegate (SwipeTableViewCellDelegate)

extension SettingsTableViewController : SwipeTableViewCellDelegate {
    /// SwipeTableViewCellDelegate
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if indexPath.section == 0 {
            let title = NSLocalizedString("Delete", comment: "Account delete")
            let deleteAction = SwipeAction(style: .destructive, title: title) { [weak self] action, indexPath in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }

                guard let row = me.viewModel.section(for: indexPath).rows[indexPath.row] as? SettingsViewModel.ActionRow,
                    let action = row.action else {
                        Log.shared.errorAndCrash(message: "There is no action for an action row")
                        return
                }

                me.showAlertBeforeDelete(indexPath: indexPath, action: action)
            }
            return (orientation == .right ? [deleteAction] : nil)
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = segueIdentifier(for: indexPath)
        switch identifier {
        case .passiveMode, .pEpSync, .protectMessageSubject, .unsecureReplyWarningEnabled:
            return
        case .resetAccounts:
            
            guard let row = viewModel.section(for: indexPath).rows[indexPath.row] as? SettingsViewModel.ActionRow, let action = row.action,
                let alert = getResetAllIdentityAlertController(action: action) else {
                    return
            }

            present(alert, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            performSegue(withIdentifier: identifier.rawValue, sender: indexPath)
        }
    }
}

// MARK: - Loading views & Editability State Change Alert

extension SettingsTableViewController : SettingsViewModelDelegate {
    
    /// Displays a loading view
    func showLoadingView() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.activityIndicatorView = UIUtils.showActivityIndicator()
        }
    }

    /// Removes the loading view
    func hideLoadingView() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.activityIndicatorView?.removeFromSuperview()
        }
    }

    func showExtraKeyEditabilityStateChangeAlert(newValue: String) {
        let title = NSLocalizedString("Extra Keys Editable", comment: "Extra Keys Editable")
        UIUtils.showAlertWithOnlyPositiveButton(title:title, message: newValue)
    }
}

// MARK: - Segue identifiers

extension SettingsTableViewController {

    /// Identifier of the segues.
    enum SegueIdentifier: String {
        case segueAddNewAccount
        case segueEditAccount
        case segueShowSettingDefaultAccount
        case sequeShowCredits
        case segueShowSettingTrustedServers
        case segueExtraKeys
        case segueSetOwnKey
        case noAccounts
        case ResetTrustSplitView
        case ResetTrust
        case noSegue
        case passiveMode
        case protectMessageSubject
        case pEpSync
        case resetAccounts
        case unsecureReplyWarningEnabled
    }

    /// Provides the segue identifier for the cell in the passed index path
    /// - Parameter indexPath: The index Path of the cell to get the segue identifier.
    /// - Returns: The segue identifier. If there is no segue to perform, it returns `noSegue`
    func segueIdentifier(for indexPath : IndexPath) -> SegueIdentifier {
        let row: SettingsRowProtocol = viewModel.section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .account:
            return .segueEditAccount
        case .defaultAccount:
            return .segueShowSettingDefaultAccount
        case .credits:
            return .sequeShowCredits
        case .trustedServer:
            return .segueShowSettingTrustedServers
        case .setOwnKey:
            return .segueSetOwnKey
        case .resetTrust:
            return .ResetTrust
        case .extraKeys:
            return .segueExtraKeys
        case .passiveMode:
            return .passiveMode
        case .protectMessageSubject:
            return .protectMessageSubject
        case .pEpSync:
            return .pEpSync
        case .resetAccounts:
            return .resetAccounts
        case .unsecureReplyWarningEnabled:
            return .unsecureReplyWarningEnabled
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }

        switch SegueIdentifier(rawValue: segueIdentifier) {
        case .segueEditAccount:
            guard let destination = segue.destination as? AccountSettingsTableViewController,
                let indexPath = sender as? IndexPath,
                let account = viewModel.account(at: indexPath) else {
                    Log.shared.error("SegueIdentifier: segueEditAccount - Early quit! Requirements not met.")
                    return
            }
            destination.appConfig = appConfig
            destination.viewModel = AccountSettingsViewModel(account: account)
        case .segueShowSettingDefaultAccount:
            guard let destination = segue.destination as? BaseTableViewController else { return }
            destination.appConfig = self.appConfig
        case .noAccounts,
             .segueAddNewAccount,
             .sequeShowCredits,
             .ResetTrust,
             .segueExtraKeys,
             .segueShowSettingTrustedServers:
            guard let destination = segue.destination as? BaseViewController else { return }
            destination.appConfig = self.appConfig
        case .none:
            break
        case .segueSetOwnKey,
             .ResetTrustSplitView,
             .noSegue,
             .passiveMode,
             .protectMessageSubject,
             .pEpSync,
             .resetAccounts,
             .unsecureReplyWarningEnabled:
            // It's all rows that never segue sanywhere (e.g. SwitchRow).
            break
        }
    }
}

// MARK: - Alert Controllers

extension SettingsTableViewController {

    private func getResetAllIdentityAlertController(action: @escaping SettingsViewModel.ActionBlock) -> PEPAlertViewController? {
        let title = NSLocalizedString("Reset All Identities", comment: "Settings confirm to reset all identity title alert")
        let message = NSLocalizedString("This action will reset all your identities. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")

        guard let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: title, message: message, paintPEPInTitle: true) else {
                Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
                return nil
        }

        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let cancelAction = PEPUIAlertAction(title: cancelTitle,
                                            style: .pEpGray) { _ in
                                                pepAlertViewController.dismiss(animated: true,
                                                                               completion: nil)
        }
        pepAlertViewController.add(action: cancelAction)

        let resetTitle = NSLocalizedString("Reset All", comment: "Reset account identity button title")

        let resetAction = PEPUIAlertAction(title: resetTitle, style: .pEpRed) { _ in
            action()
            pepAlertViewController.dismiss()
        }

        pepAlertViewController.add(action: resetAction)

        pepAlertViewController.modalPresentationStyle = .overFullScreen
        pepAlertViewController.modalTransitionStyle = .crossDissolve
        return pepAlertViewController
    }

    private func getBeforeDeleteAlert(deleteCallback: @escaping SettingsViewModel.AlertActionBlock) -> UIAlertController {
        let title = NSLocalizedString("Are you sure you want to delete the account?", comment: "Account delete confirmation")
        let comment = NSLocalizedString("delete account message", comment: "Account delete confirmation comment")
        let deleteButtonTitle = NSLocalizedString("Delete", comment: "Delete account button title")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel title button")

        let alert = UIAlertController.pEpAlertController(title: title, message: comment, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: deleteButtonTitle, style: .destructive) { _ in
            deleteCallback()
        }
        alert.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel)
        alert.addAction(cancelAction)
        return alert
    }

    func showpEpSyncLeaveGroupAlert(action:  @escaping SettingsViewModel.SwitchBlock, newValue: Bool) -> PEPAlertViewController? {
        let title = NSLocalizedString("Disable p≡p Sync",
                                      comment: "Leave device group confirmation")
        let comment = NSLocalizedString("If you disable p≡p Sync, your accounts on your devices will not be synchronised anymore. Are you sure you want to disable p≡p Sync?",
                                        comment: "Alert: Leave device group confirmation comment")

        let alert = PEPAlertViewController.fromStoryboard(title: title,
                                                          message: comment,
                                                          paintPEPInTitle: false,
                                                          viewModel: PEPAlertViewModel(alertType: .pEpSyncWizard))
        let cancelAction = PEPUIAlertAction(title: NSLocalizedString("Cancel",
                                                                     comment: "keysync alert leave device group cancel"),
                                            style: .pEpDarkText) { [weak self] _ in
                                                guard let me = self else {
                                                    Log.shared.lostMySelf()
                                                    return
                                                }
                                                //Switch status needs to be reversed
                                                me.tableView.reloadData()
                                                alert?.dismiss()
        }

        alert?.add(action: cancelAction)

        let disableAction = PEPUIAlertAction(title: NSLocalizedString("Disable",
                                                                      comment: "keysync alert leave device group disable"),
                                             style: .pEpDarkText) { _ in
                                                action(newValue)
                                                alert?.dismiss()
        }
        alert?.add(action: disableAction)
        return alert
    }
}

// MARK: - SwitchCellDelegate

extension SettingsTableViewController: SwitchCellDelegate {
    func switchSettingCell(_ sender: SettingSwitchTableViewCell,
                           didChangeSwitchStateTo newValue: Bool) {
        guard let indexPath = tableView.indexPath(for: sender) else {
            Log.shared.error("The switch cell can't be found")
            return
        }
        let section = viewModel.section(for: indexPath) as SettingsViewModel.Section
        guard let row = section.rows[indexPath.row] as? SettingsViewModel.SwitchRow else {
            Log.shared.error("lost row")
            return
        }

        if row.identifier == SettingsViewModel.Row.pEpSync {
            if viewModel.isGrouped() {
                guard let alertToShow = showpEpSyncLeaveGroupAlert(action: row.action,
                                                                   newValue: newValue) else {
                                                                    Log.shared.error("alert lost")
                                                                    return
                }
                present(alertToShow, animated: true)
            } else {
                row.action(newValue)
            }
        } else {
            row.action(newValue)
        }
    }
}
