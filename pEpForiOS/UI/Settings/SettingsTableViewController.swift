//
//  SettingsTableViewController.swift
//  pEp
//
//  Created by Martin Brude on 22/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import SwipeCellKit
import PlanckToolbox

final class SettingsTableViewController: UITableViewController {

    static let storyboardId = "SettingsTableViewController"
    private weak var activityIndicatorView: UIActivityIndicatorView?

    public private(set) lazy var viewModel = SettingsViewModel(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotifications()
        setUp()
        viewModel.delegate = self
        UIHelper.variableCellHeightsTableView(tableView)
        UIHelper.variableSectionHeadersHeightTableView(tableView)
        addExtraKeysEditabilityToggleGesture()
        setBackButtonAccessibilityLabel()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pEpMDMSettingsChanged),
                                               name: .pEpMDMSettingsChanged,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
        navigationController?.setToolbarHidden(true, animated: false)
        showEmptyDetailViewIfApplicable(message: NSLocalizedString("Please choose a setting",
                                                                   comment: "No setting has been selected yet in the settings VC"))
        UIUtils.hideBanner()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    @objc private func pEpMDMSettingsChanged() {
        viewModel = SettingsViewModel(delegate: self)
        tableView.reloadData()
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
        view.backgroundColor = UIColor.systemGroupedBackground
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
        cell.accessibilityIdentifier = row.title
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
        dequeuedCell.accessibilityIdentifier = row.title
        switch row.identifier {
        case .trustedServer:
            Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
            return UITableViewCell()
        case .account:
            return prepareSwipeTableViewCell(dequeuedCell, for: row)
        case .resetAccounts,
             .resetTrust,
             .planckSync:
            if let cell = dequeuedCell as? SettingsActionTableViewCell, row.identifier == .planckSync {
                cell.activityIndicatorIsOn = AppSettings.shared.keyPlanckSyncActivityIndicatorIsOn
            }
            return prepareActionCell(dequeuedCell, for: row)
        case .defaultAccount,
             .pgpKeyImport,
             .credits,
             .userManual,
             .termsAndConditions,
             .extraKeys,
             .exportDBs,
             .auditLogging,
             .groupMailboxes,
             .deviceGroups,
             .about:
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
             .usePlanckFolder,
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
        case .planckSync:
            tableView.deselectRow(at: indexPath, animated: true)
            if !NetworkMonitorUtil.shared.netOn {
                //Inform the user if there is no internet connection.
                UIUtils.showNoInternetConnectionBanner(viewController: self)
                return
            }
            viewModel.handlePlanckSyncPressed()
            return
        case .exportDBs:
            showExportDBsAlert()
            tableView.deselectRow(at: indexPath, animated: true)
            return
        case .userManual:
            tableView.deselectRow(at: indexPath, animated: true)
            
            if !NetworkMonitorUtil.shared.netOn {
                //Inform the user if there is no internet connection.
                UIUtils.showNoInternetConnectionBanner(viewController: self)
                return
            }
            guard let urlString = InfoPlist.userManualURL(),
                  let url = URL(string: urlString),
                  UIApplication.shared.canOpenURL(url) else {
                Log.shared.errorAndCrash("Can't open url")
                break
            }
            UIApplication.shared.open(url, options: [:])
            return
        case .termsAndConditions:
            tableView.deselectRow(at: indexPath, animated: true)
            
            if !NetworkMonitorUtil.shared.netOn {
                //Inform the user if there is no internet connection.
                UIUtils.showNoInternetConnectionBanner(viewController: self)
                return
            }
            guard let urlString = InfoPlist.termsAndConditionsURL(),
                  let url = URL(string: urlString),
                  UIApplication.shared.canOpenURL(url) else {
                Log.shared.errorAndCrash("Can't open url")
                break
            }
            UIApplication.shared.open(url, options: [:])
            return
        case .account,
             .extraKeys,
             .resetTrust,
             .pgpKeyImport,
             .trustedServer,
             .credits,
             .defaultAccount,
             .auditLogging:
            let identifier = sequeIdentifier(forRowWithIdentifier: row.identifier).rawValue
            performSegue(withIdentifier: identifier, sender: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
        case .resetAccounts:
            guard let row = viewModel.section(for: indexPath).rows[indexPath.row] as? SettingsViewModel.ActionRow, let action = row.action else {
                return
            }
            viewModel.handleResetAllIdentitiesPressed(action:action)
            tableView.deselectRow(at: indexPath, animated: true)
        case .passiveMode,
             .usePlanckFolder,
             .protectMessageSubject,
             .unsecureReplyWarningEnabled,
             .groupMailboxes,
             .deviceGroups,
             .about:
            tableView.deselectRow(at: indexPath, animated: true)
            // Nothing to do.
            return
        }
    }
}

// MARK: - Loading views & Editability State Change Alert

extension SettingsTableViewController : SettingsViewModelDelegate {

    private func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeActivityIndicatorOnPlanckSync),
                                               name: .planckSyncActivityIndicatorChanged,
                                               object: nil)
    }

    @objc func changeActivityIndicatorOnPlanckSync() {
        let cells = tableView.visibleCells.filter({$0 is SettingsActionTableViewCell })
        let ip = IndexPath(row: 0, section: 2) // Planck Sync Index Path
        let section = viewModel.section(for: ip) as SettingsViewModel.Section
        guard let row = section.rows[ip.row] as? SettingsViewModel.NavigationRow else {
            Log.shared.errorAndCrash("lost row")
            return
        }
        if let planckSyncCell = cells.filter({$0.textLabel?.text == row.title }).first as? SettingsActionTableViewCell {
            if AppSettings.shared.keyPlanckSyncActivityIndicatorIsOn {
                planckSyncCell.startActivityIndicator()
            } else {
                planckSyncCell.stopActivityIndicator()
            }
        }
    }

    func showFeedback(title: String, message: String) {
        UIUtils.showAlertWithOnlyCloseButton(title: title, message: message)
    }

    func showTryAgain(title: String, message: String) {
        UIUtils.showTwoButtonAlert(withTitle: title, message: message) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.viewModel.handleTryAgainResetAllIdentities()
        }
    }

    /// Displays a loading view
    func showLoadingView() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            //Lets prevent a stack of activity indicators
            me.activityIndicatorView?.stopAnimating()
            me.activityIndicatorView?.removeFromSuperview()
            me.activityIndicatorView = UIUtils.showActivityIndicator(viewController: me)
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
    
    func informReinitFailed() {
        if UIApplication.currentlyVisibleViewController() is KeySyncWizardViewController {
            // Nothing to show.
            return
        }
        let errorTitle = NSLocalizedString("Device Sync cannot be started", comment: "Device Sync cannot be started")
        let errorMessage = NSLocalizedString("The user should try again", comment: "the user should try again")
        UIUtils.showAlertWithOnlyCloseButton(title: errorTitle, message: errorMessage)
    }

    func showExtraKeyEditabilityStateChangeAlert(newValue: String) {
        let title = NSLocalizedString("Extra Keys Editable", comment: "Extra Keys Editable")
        UIUtils.showAlertWithOnlyPositiveButton(title:title, message: newValue)
    }
    
    func showResetAllWarning(callback: @escaping SettingsViewModel.ActionBlock) {
        let title = NSLocalizedString("Reset All Identities", comment: "Settings confirm to reset all identity title alert")
        let message = NSLocalizedString("Resetting your key pair generates new private and public keys for you that planck will immediately start using.\n\nResetting also removes your device from any device group.\n\nAre you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let resetTitle = NSLocalizedString("Yes, Reset", comment: "Reset account identity button title")
        UIUtils.showTwoButtonAlert(withTitle: title, message: message, cancelButtonText: cancelTitle, positiveButtonText: resetTitle, positiveButtonAction: {
            callback()
        },
        style: PlanckAlertViewController.AlertStyle.warn)
    }

    func showDBExportSuccess() {
        let alertTitle = NSLocalizedString("Export planck databases to file system", comment: "Alert view title - warning")
        let message = NSLocalizedString("Exporting databases OK", comment: "Error message")
        UIUtils.showAlertWithOnlyPositiveButton(title: alertTitle, message: message, style: .undo, completion: nil)
    }

    func showDBExportFailed() {
        let alertTitle = NSLocalizedString("Export planck databases to file system", comment: "Alert view title - warning")
        let message = NSLocalizedString("Exporting databases failed", comment: "Error message")
        let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button")
        let tryAgainButton = NSLocalizedString("Try Again", comment: "Try again button text")
        UIUtils.showTwoButtonAlert(withTitle: alertTitle, message: message, cancelButtonText: cancelButton, positiveButtonText:tryAgainButton, cancelButtonAction: nil, positiveButtonAction: { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.dismiss(animated: true) {
                me.viewModel.handleExportDBsPressed()
            }
        }, style: .undo)
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
        case segueGroupMailboxes
        case segueDeviceGroups
        case segueAbout
        case segueAuditLogging
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
        case .passiveMode, .usePlanckFolder, .unsecureReplyWarningEnabled, .protectMessageSubject, .resetAccounts, .exportDBs:
            return .none
        case .groupMailboxes:
            return .none // .segueGroupMailboxes
        case .deviceGroups:
            return .none // .segueDeviceGroups
        case .about:
            return .none // .segueAbout
        case .userManual:
            return .none
        case .termsAndConditions:
            return .none
        case .auditLogging:
            return .segueAuditLogging
        case .planckSync:
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
             .segueGroupMailboxes,
             .segueDeviceGroups,
             .segueAbout:
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
        case .segueAuditLogging:
            guard let destination = segue.destination as? AuditLoggingViewController else {
                Log.shared.errorAndCrash("No DVC")
                return
            }
            destination.viewModel = viewModel.auditLoggingViewModel()
        case .none:
            // It's all rows that never segue anywhere (e.g. SwitchRow). Thus this should never be called.
            Log.shared.errorAndCrash("Must not be called (prepares for segue for rows that are not supposed to segue anywhere).")
            break
        }
    }
}

// MARK: - Alert Controllers

extension SettingsTableViewController {

    private func showExportDBsAlert() {
        let alertTitle = NSLocalizedString("Export planck databases to file system", comment: "Alert view title - warning")
        let message = NSLocalizedString("Do you really want to export planck databases to Documents/planck/db-export/ on your local file system?\nWarning: The databases contain confidential information like private keys.",
                                        comment: "Alert view message - warning")
        let cancelButtonText = NSLocalizedString("No", comment: "No button")
        let positiveButtonText = NSLocalizedString("Yes", comment: "Yes button")
        UIUtils.showTwoButtonAlert(withTitle: alertTitle,
                                   message: message,
                                   cancelButtonText: cancelButtonText,
                                   positiveButtonText: positiveButtonText,
                                   cancelButtonAction: nil,
                                   positiveButtonAction: { [weak self] in
                                    guard let me = self else {
                                        Log.shared.errorAndCrash("Lost myself")
                                        return
                                    }
                                    me.dismiss(animated: true) {
                                        me.viewModel.handleExportDBsPressed()
                                    }
                                   },
                                   style: .undo)
    }

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

    private func showpEpSyncLeaveGroupAlert(action:  @escaping SettingsViewModel.SwitchBlock, newValue: Bool) -> PlanckAlertViewController? {
        let title = NSLocalizedString("Disable planck Sync",
                                      comment: "Leave device group confirmation")
        let comment = NSLocalizedString("If you disable planck Sync, your accounts on your devices will not be synchronised anymore. Are you sure you want to disable planck Sync?",
                                        comment: "Alert: Leave device group confirmation comment")

        let alert = PlanckAlertViewController.fromStoryboard(title: title,
                                                          message: comment,
                                                          paintPEPInTitle: false,
                                                          viewModel: PlanckAlertViewModel(alertType: .planckSyncWizard))
        var style: UIColor = .pEpDarkText
        style = .label
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "keysync alert leave device group cancel")
        let cancelAction = PlanckUIAlertAction(title: cancelActionTitle, style: style) { [weak self] _ in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            //Switch status needs to be reversed
            me.tableView.reloadData()
            alert?.dismiss()
        }
        alert?.add(action: cancelAction)
        
        let disableActionTitle = NSLocalizedString("Disable", comment: "keysync alert leave device group disable")
        let disableAction = PlanckUIAlertAction(title: disableActionTitle, style: style) { _ in
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

        if row.identifier == SettingsViewModel.RowIdentifier.planckSync {
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
