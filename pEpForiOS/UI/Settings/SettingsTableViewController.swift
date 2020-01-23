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

class SettingsTableViewController: BaseTableViewController, SwipeTableViewCellDelegate, SettingsViewControllerDelegate {
        
    static let storyboardId = "SettingsTableViewController"
    private weak var activityIndicatorView: UIActivityIndicatorView?

    lazy var viewModelv2 = SettingsViewModel()
    
    //TODO: get this instance
    var settingSwitchViewModel: SwitchSettingCellViewModelProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModelv2.delegate = self
        title = NSLocalizedString("Settings", comment: "Settings view title")
        UIHelper.variableCellHeightsTableView(tableView)
        addExtraKeysEditabilityToggleGesture()
    }
    
    /// MARK: Extra Keys
    /// Adds easter egg gesture to [en|dis]able the editability of extra keys
    private func addExtraKeysEditabilityToggleGesture() {
        let gestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(extraKeysEditabilityToggleGestureTriggered))
        gestureRecogniser.numberOfTapsRequired = 6
        gestureRecogniser.numberOfTouchesRequired = 3
        tableView.addGestureRecognizer(gestureRecogniser)
    }
    
    /// [en|dis]able the editability of extra keys
    @objc private func extraKeysEditabilityToggleGestureTriggered() {
        viewModelv2.handleExtraKeysEditabilityGestureTriggered()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModelv2.section(for: section).rows.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModelv2.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModelv2.section(for: section).title
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModelv2.section(for: section).footer
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dequeueCell(for: tableView, for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }
    
    /// SwipeTableViewCellDelegate
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if indexPath.section == 0 {
            let title = NSLocalizedString("Delete", comment: "Account delete")
            let deleteAction = SwipeAction(style: .destructive, title: title) { [weak self] action, indexPath in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.showAlertBeforeDelete(indexPath)
            }
            return (orientation == .right ? [deleteAction] : nil)
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = segueIdentifier(for: indexPath)
        switch identifier {
        case .passiveMode, .pEpSync, .protectMessageSubject:
        return //Must not perform any segue.
        case .resetAccounts:
            handleResetAllIdentity()
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            performSegue(withIdentifier: identifier.rawValue, sender: indexPath)
        }
    }
    
    /// MARK: - Private.

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
        cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
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
        dequeuedCell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
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
        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
        cell.viewModel = settingSwitchViewModel
        cell.selectionStyle = .none
        cell.setUpView()
        return cell
    }
    
    /// Method to get the cell of the table view configured.
    /// - Parameters:
    ///   - tableView: The table view to dequeue the cell
    ///   - indexPath: The indexPath to identify the cell. 55
    private func dequeueCell(for tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cellId = viewModelv2.cellIdentifier(for: indexPath)
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        let row : SettingsRowProtocol = viewModelv2.section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .account:
            return prepareSwipeTableViewCell(dequeuedCell, for: row)
        case .resetAccounts, .accountsToSync, .resetTrust, .pEpSync:
            return prepareActionCell(dequeuedCell, for: row)
        case .defaultAccount, .setOwnKey, .credits, .trustedServer, .extraKeys:
            guard let row = row as? SettingsViewModel.NavigationRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            dequeuedCell.textLabel?.text = row.title
            dequeuedCell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
            dequeuedCell.detailTextLabel?.text = row.subtitle
            return dequeuedCell
        case .passiveMode, .protectMessageSubject:
            guard let row = row as? SettingsViewModel.SwitchRow else {
                Log.shared.errorAndCrash(message: "Row doesn't match the expected type")
                return UITableViewCell()
            }
            return prepareSwitchTableViewCell(dequeuedCell, for: row)
        }
    }
    
    /// Presents an alert controller if the user taps the reset all identity cell.
    private func handleResetAllIdentity() {
        if let pepAlertViewController = viewModelv2.getResetAllIdentityAlertController() {
            DispatchQueue.main.async { [weak self] in
                self?.present(pepAlertViewController, animated: true)
            }
        }
    }
    
    /// Shows the alert controller before deleting an account
    /// - Parameter indexPath: The index to delete the row in case of acceptance.
    private func showAlertBeforeDelete(_ indexPath: IndexPath) {
        let alertController = viewModelv2.getBeforeDeleteAlert { [weak self] action in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }

            //This should never happened
            if me.viewModelv2.noAccounts() {
                me.performSegue(withIdentifier: "noAccounts", sender: nil)
                return
            }

            //FIXME: this crashes.
            me.tableView.beginUpdates()
//            if let pEpSyncSection = me.viewModelv2.pEpSyncSection() {
//                me.tableView.reloadSections([pEpSyncSection], with: UITableView.RowAnimation.none)
//            }
            me.tableView.deleteRows(at: [indexPath], with: .fade)
            me.tableView.endUpdates()
        }
        
        if alertController != nil {
            present(alertController!, animated: true)
        }
    }
    
    
        private func deleteRowAt(_ indexPath: IndexPath) {
            self.viewModelv2.deleteRowAt(indexPath)
    //
    //        if let position =  navigationController?.viewControllers.count, let previousVc = navigationController?.viewControllers[position - 1] as? EmailViewController {
    //            if viewModel.canBeShown(Message: previousVc.message) {
    //                navigationController?.viewControllers.remove(at: position-1)
    //            }
    //        }
            if self.viewModelv2.noAccounts() {
                self.performSegue(withIdentifier: "noAccounts", sender: nil)
            }
        }

}

extension SettingsTableViewController {
    
    /// Displays a loading view
    func showLoadingView() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.activityIndicatorView = me.showActivityIndicator()
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
        UIUtils.showAlertWithOnlyPositiveButton(title:title, message: newValue, inViewController: self)
    }
        
    func showpEpSyncLeaveGroupAlert() {
        
    }
    
    func showResetIdentitiesAlert() {
        
    }
}

/// MARK: - Segue identifier

extension SettingsTableViewController {
    
    /// Provides the segue identifier for the cell in the passed index path
    /// - Parameter indexPath: The index Path of the cell to get the segue identifier.
    /// - Returns: The segue identifier. If there is no segue to perform, it returns `noSegue`
    func segueIdentifier(for indexPath : IndexPath) -> SettingsViewModel.SegueIdentifier {
        let row : SettingsRowProtocol = viewModelv2.section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .account:
            return SettingsViewModel.SegueIdentifier.segueEditAccount
        case .defaultAccount:
            return SettingsViewModel.SegueIdentifier.segueShowSettingDefaultAccount
        case .credits:
            return SettingsViewModel.SegueIdentifier.sequeShowCredits
        case .trustedServer:
            return SettingsViewModel.SegueIdentifier.segueShowSettingTrustedServers
        case .setOwnKey:
            return SettingsViewModel.SegueIdentifier.segueSetOwnKey
        case .accountsToSync:
            return SettingsViewModel.SegueIdentifier.seguePerAccountSync
        case .resetTrust:
            return SettingsViewModel.SegueIdentifier.ResetTrust
        case .extraKeys:
            return SettingsViewModel.SegueIdentifier.segueExtraKeys
        case .passiveMode:
            return SettingsViewModel.SegueIdentifier.passiveMode
        case .protectMessageSubject:
            return SettingsViewModel.SegueIdentifier.protectMessageSubject
        case .pEpSync:
            return SettingsViewModel.SegueIdentifier.pEpSync
        case .resetAccounts:
            return SettingsViewModel.SegueIdentifier.resetAccounts
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }
        
        switch SettingsViewModel.SegueIdentifier(rawValue: segueIdentifier) {
        case .segueEditAccount:
            guard let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? AccountSettingsTableViewController,
                let indexPath = sender as? IndexPath else { return }
            destination.appConfig = appConfig
            guard let account = viewModelv2.account(at: indexPath) else { return }
            destination.viewModel = AccountSettingsViewModel(account: account)
        case .segueShowSettingDefaultAccount,
             .segueShowSettingTrustedServers:
            guard let destination = segue.destination as? BaseTableViewController else { return }
            destination.appConfig = self.appConfig
        case .noAccounts,
            .segueAddNewAccount,
            .sequeShowCredits,
            .ResetTrust,
            .segueExtraKeys,
            .seguePerAccountSync:
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
             .resetAccounts:
            // TOD: add log for this.
            // let message = "No configuration to apply before segue \(segueIdentifier)";
            break
        }
    }

}

/// MARK: - Alert Controllers

extension SettingsViewModel {
    
    func getResetAllIdentityAlertController() -> PEPAlertViewController? {
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
        let resetAction = PEPUIAlertAction(title: resetTitle,
                                           style: .pEpRed,
                                           handler: { [weak self] _ in
                                            
                                            guard let strongSelf = self else {
                                                Log.shared.lostMySelf()
                                                return
                                            }
                                            pepAlertViewController.dismiss(animated: true, completion: nil)
                                            strongSelf.handleResetAllIdentities()
        })
        pepAlertViewController.add(action: resetAction)
        
        pepAlertViewController.modalPresentationStyle = .overFullScreen
        pepAlertViewController.modalTransitionStyle = .crossDissolve
        return pepAlertViewController
    }
    
    func getBeforeDeleteAlert(deleteCallback : @escaping AlertActionBlock) -> UIAlertController? {
        let title = NSLocalizedString("Are you sure you want to delete the account?", comment: "Account delete confirmation")
        let comment = NSLocalizedString("delete account message", comment: "Account delete confirmation comment")
        let buttonTitle = NSLocalizedString("Delete", comment: "Delete account button title")
        
        let message = NSLocalizedString(title, comment: comment)
        let alertController = UIAlertController.pEpAlertController(title: nil, message:message, preferredStyle: .actionSheet)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel title button")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: buttonTitle, style: .destructive, handler: deleteCallback)
        alertController.addAction(destroyAction)
        return alertController
    }
}
