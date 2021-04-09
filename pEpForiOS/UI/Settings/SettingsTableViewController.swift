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

final class SettingsTableViewController: UITableViewController {

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
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
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
    private struct Localized {
        static let navigationTitle = NSLocalizedString("Settings",
                                                       comment: "Settings view title")
    }
    private func setUp() {
        title = Localized.navigationTitle
        tableView.register(PEPHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemGroupedBackground
        } else {
            view.backgroundColor = .groupTableViewBackground
        }
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
    private func prepareSwitchTableViewCell(_ dequeuedCell: UITableViewCell?,
                                            for row: SettingsViewModel.SwitchRow) -> SettingSwitchTableViewCell {
        guard let cell = dequeuedCell as? SettingSwitchTableViewCell else {
            Log.shared.errorAndCrash("Invalid state.")
            return SettingSwitchTableViewCell()
        }
        cell.switchDescription.text = row.title
        cell.switchDescription.font = UIFont.pepFont(style: .body, weight: .regular)
        cell.switchDescription.textColor = viewModel.titleColor(rowIdentifier: row.identifier)
        cell.delegate = self
        cell.selectionStyle = .none
        cell.switchItem.setOn(row.isOn, animated: false)
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
        case .resetAccounts,
             .resetTrust:
            return prepareActionCell(dequeuedCell, for: row)
        case .defaultAccount,
             .pgpKeyImport,
             .credits,
             .trustedServer,
             .extraKeys,
             .tutorial:
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
        case .passiveMode,
             .protectMessageSubject,
             .pEpSync,
             .usePEPFolder,
             .unsecureReplyWarningEnabled:
            guard let row = row as? SettingsViewModel.SwitchRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            return prepareSwitchTableViewCell(dequeuedCell, for: row)
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

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
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
            deleteAction.hidesWhenSelected = true
            return (orientation == .right ? [deleteAction] : nil)
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = viewModel.section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .tutorial:
            TutorialWizardViewController.presentTutorialWizard(viewController: self)
            tableView.deselectRow(at: indexPath, animated: true)
            return
        case .account,
             .extraKeys,
             .resetTrust,
             .pgpKeyImport,
             .trustedServer,
             .credits,
             .defaultAccount:
            performSegue(withIdentifier: sequeIdentifier(forRowWithIdentifier: row.identifier).rawValue,
                         sender: indexPath)
        case .resetAccounts:
            guard let row = viewModel.section(for: indexPath).rows[indexPath.row] as? SettingsViewModel.ActionRow, let action = row.action else {
                return
            }
            viewModel.handleResetAllIdentitiesPressed(action:action)
            tableView.deselectRow(at: indexPath, animated: true)
        case .passiveMode,
             .pEpSync,
             .usePEPFolder,
             .protectMessageSubject,
             .unsecureReplyWarningEnabled:
            // Nothing to do.
            return
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
    
    func showResetAllWarning(callback: @escaping SettingsViewModel.ActionBlock) {
        let title = NSLocalizedString("Reset All Identities", comment: "Settings confirm to reset all identity title alert")
        let message = NSLocalizedString("This action will reset all your identities. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let resetTitle = NSLocalizedString("Reset All", comment: "Reset account identity button title")
        UIUtils.showTwoButtonAlert(withTitle: title, message: message, cancelButtonText: cancelTitle, positiveButtonText: resetTitle, positiveButtonAction: {
            callback()
        },
        style: PEPAlertViewController.AlertStyle.warn)
    }
}

// MARK: - Segue identifiers

extension SettingsTableViewController {

     /// Identifier of the segues.
    enum SegueIdentifier: String {
        case segueAddNewAccount //???: how can you add a new account in setting? Please check if obsolete and remove if so.
        case segueEditAccount
        case segueShowSettingDefaultAccount
        case sequeShowCredits
        case segueShowSettingTrustedServers
        case segueExtraKeys
        case seguePgpKeyImport
        case noAccounts
        case resetTrust
        case tutorial
        /// Use for cells that do not segue, like switch cells
        case none
    }

    private func sequeIdentifier(forRowWithIdentifier identifier: SettingsViewModel.RowIdentifier) -> SegueIdentifier {
        switch identifier {
        case .account:
            return .segueEditAccount
        case .defaultAccount:
            return .segueShowSettingDefaultAccount
        case .credits:
            return .sequeShowCredits
        case .trustedServer:
            return .segueShowSettingTrustedServers
        case .pgpKeyImport:
            return .seguePgpKeyImport
        case .resetTrust:
            return .resetTrust
        case .extraKeys:
            return .segueExtraKeys
        case .tutorial:
            return .tutorial
        case .passiveMode, .usePEPFolder, .pEpSync, .unsecureReplyWarningEnabled, .protectMessageSubject, .resetAccounts:
            return .none
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let id = segue.identifier,
            let segueIdentifyer = SegueIdentifier(rawValue: id)
            else {
                Log.shared.errorAndCrash("No SegueIdentifier")
                return

        }

        switch segueIdentifyer {
        case .segueEditAccount:
            guard let destination = segue.destination as? AccountSettingsViewController,
                let indexPath = sender as? IndexPath,
                let account = viewModel.account(at: indexPath) else {
                    Log.shared.error("SegueIdentifier: segueEditAccount - Early quit! Requirements not met.")
                    return
            }
            destination.viewModel = AccountSettingsViewModel(account: account)

        case .segueShowSettingDefaultAccount,
             .noAccounts,
             .segueAddNewAccount,
             .sequeShowCredits,
             .resetTrust,
             .segueExtraKeys,
             .segueShowSettingTrustedServers,
             .tutorial:
            // Nothing to prepare for those seques
            // We do not use ´default´ in switch because it is less error prone.
            // So if the destination vc doesn't need anything we just let it in this case.
            break
        case .seguePgpKeyImport:
            guard let destination = segue.destination as? PGPKeyImportSettingViewController else {
                Log.shared.errorAndCrash("No DVC")
                return
            }
            destination.viewModel = viewModel.pgpKeyImportSettingViewModel()
        case .none:
            // It's all rows that never segue anywhere (e.g. SwitchRow). Thus this should never be called.
            Log.shared.errorAndCrash("Must not be called (prepares for segue for rows that are not supposed to segue anywhere).")
            break
        }
    }
}

// MARK: - Alert Controllers

extension SettingsTableViewController {

    private func getBeforeDeleteAlert(deleteCallback: @escaping SettingsViewModel.AlertActionBlock) -> UIAlertController {
        let title = NSLocalizedString("Are you sure you want to delete the account?", comment: "Account delete confirmation")
        let deleteButtonTitle = NSLocalizedString("Delete", comment: "Delete account button title")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel title button")
        let alert = UIUtils.actionSheet(title: title)
        let deleteAction = UIAlertAction(title: deleteButtonTitle, style: .destructive) { _ in
            deleteCallback()
        }
        alert.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel)
        alert.addAction(cancelAction)
        return alert
    }

    private func showpEpSyncLeaveGroupAlert(action:  @escaping SettingsViewModel.SwitchBlock, newValue: Bool) -> PEPAlertViewController? {
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

        if row.identifier == SettingsViewModel.RowIdentifier.pEpSync {
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
