////
////  SettingsTableViewController.swift
////  pEpForiOS
////
////  Created by Dirk Zimmermann on 19/08/16.
////  Copyright © 2016 p≡p Security S.A. All rights reserved.
////
//
//import SwipeCellKit
//import pEpIOSToolbox
//
//class SettingsTableViewControllerV1: BaseTableViewController, SwipeTableViewCellDelegate {
//    static let storyboardId = "SettingsTableViewController"
//    lazy var viewModelv1 = SettingsViewModel()
//    lazy var viewModelv2 = SettingsViewModel()
//
//    var settingSwitchViewModel: SwitchSettingCellViewModelProtocol?
//
//    private weak var activityIndicatorView: UIActivityIndicatorView?
//
//    var ipath : IndexPath?
//
//    struct UIState {
//        var isSynching = false
//    }
//
//    var state = UIState()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        title = NSLocalizedString("Settings", comment: "Settings view title")
//        UIHelper.variableCellHeightsTableView(tableView)
//        addExtraKeysEditabilityToggleGesture()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        navigationController?.setToolbarHidden(true, animated: false)
////        viewModelv1.delegate = self
//
//        tableView.reloadData()
//
//        showEmptyDetailViewIfApplicable(
//            message: NSLocalizedString(
//                "Please choose a setting",
//                comment: "No setting has been selected yet in the settings VC"))
//    }
//
//    // MARK: - UITableViewDataSource
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return  viewModelv2.section(for: section).rows.count
//    }
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return viewModelv2.count
//    }
//
//    override func tableView(_ tableView: UITableView,
//                            titleForHeaderInSection section: Int) -> String? {
//        return viewModelv2.section(for: section).title
//    }
//
//    override func tableView(_ tableView: UITableView,
//                            titleForFooterInSection section: Int) -> String? {
//        return viewModelv2.section(for: section).footer
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        ///TODO: REVIEW THIS METHOD. - WE MUST USE ONLY ViewModelv2
//        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: viewModelv1[indexPath.section][indexPath.row].cellIdentifier, for: indexPath)
//
//        let row : SettingsRowProtocol = viewModelv2.section(for: indexPath.section).rows[indexPath.row]
//
//        switch row.identifier {
//        case .account:
//            return prepareSwipeTableViewCell(dequeuedCell, for: row)
//        case .resetAccounts:
//            return prepareActionCell(dequeuedCell, for: row)
//        case .defaultAccount:
//            if let row = row as? SettingsViewModelV2.NavigationRow {
//                let cell = dequeuedCell
//                cell.textLabel?.text = row.title
//                cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
//                cell.detailTextLabel?.text = row.subtitle
//                return cell
//            }
//            return UITableViewCell()
//        case .credits:
//            return prepareActionCell(dequeuedCell, for: row)
//        case .trustedServer:
//            return prepareActionCell(dequeuedCell, for: row)
//        case .setOwnKey:
//            return prepareActionCell(dequeuedCell, for: row)
//        case .passiveMode:
//            if let row = row as? SettingsViewModelV2.SwitchRow {
//                return prepareSwitchTableViewCell(dequeuedCell, for: row)
//            }
//            return UITableViewCell()
//        case .protectMessageSubject:
//            if let row = row as? SettingsViewModelV2.SwitchRow {
//                return prepareSwitchTableViewCell(dequeuedCell, for: row)
//            }
//            return UITableViewCell()
//
//        case .pEpSync:
//            guard let row = row as? SettingsViewModelV2.SwitchRow,
//                let cell = dequeuedCell as? SettingSwitchTableViewCell else {
//                Log.shared.errorAndCrash(message: "Dequeued Cell error")
//                return UITableViewCell()
//            }
//            
//            cell.textLabel?.text = row.title
//            cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
//            cell.setUpView()
//            return cell
//            
//        case .accountsToSync, .resetTrust:
//            return prepareActionCell(dequeuedCell, for: row)
//        case .extraKeys:
//            return prepareActionCell(dequeuedCell, for: row)
//        }
//    }
//
//    func tableView(_ tableView: UITableView,
//                   editActionsForRowAt indexPath: IndexPath,
//                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
//        if indexPath.section == 0 {
//            let deleteAction =
//                SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Account delete")) {
//                    [weak self] action, indexPath in
//                    guard let me = self else {
//                        Log.shared.lostMySelf()
//                        return
//                    }
//                    me.showAlertBeforeDelete(indexPath)
//            }
//            return (orientation == .right ? [deleteAction] : nil)
//        }
//
//        return nil
//    }
//
//    func tableView(_ tableView: UITableView,
//                   editActionsOptionsForRowAt indexPath: IndexPath,
//                   for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
//        var options = SwipeTableOptions()
//        options.expansionStyle = .none
//        options.transitionStyle = .border
//        return options
//    }
//
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return indexPath.section == 0 ? true : false
//    }
//
//    // MARK: - Table view delegate
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let vm = viewModelv1[indexPath.section][indexPath.row]
//
//        switch vm {
//        case let vm as ComplexSettingCellViewModelProtocol:
//            switch vm.type {
//            case .account:
//                self.ipath = indexPath
//                performSegue(withIdentifier: .segueEditAccount, sender: self)
//            case .defaultAccount:
//                performSegue(withIdentifier: .segueShowSettingDefaultAccount, sender: self)
//            case .credits:
//                performSegue(withIdentifier: .sequeShowCredits, sender: self)
//            case .trustedServer:
//                performSegue(withIdentifier: .segueShowSettingTrustedServers, sender: self)
//            case .setOwnKey:
//                performSegue(withIdentifier: .segueSetOwnKey, sender: self)
//            case .extraKeys:
//                performSegue(withIdentifier: .segueExtraKeys, sender: self)
//            case .accountsToSync:
//                performSegue(withIdentifier: .seguePerAccountSync , sender: self)
//            case .resetTrust:
//                performSegue(withIdentifier: .ResetTrust, sender: self)
//            }
//
//        case let vm as SettingsActionCellViewModel:
//            switch vm.type {
//            case .resetAllIdentities:
//                handleResetAllIdentity()
//                tableView.deselectRow(at: indexPath, animated: true)
//            }
//        default:
//            // SwitchSettingCellViewModelProtocol will drop here, but nothing to do when selected
//            break
//        }
//    }
//    
//    /// MARK: - Prepare cells
//    
//    private func prepareActionCell(_ dequeuedCell: UITableViewCell, for row: SettingsRowProtocol) -> UITableViewCell {
//        let cell = dequeuedCell
//        cell.textLabel?.text = row.title
//        cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
//        return cell
//    }
//    
//    private func prepareSwipeTableViewCell(_ dequeuedCell: UITableViewCell?, for row: SettingsRowProtocol) -> UITableViewCell {
//        guard let cell = dequeuedCell as? SwipeTableViewCell else {
//            Log.shared.errorAndCrash("Invalid state.")
//            return UITableViewCell()
//        }
//        cell.textLabel?.text = row.title
//        cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
//        cell.delegate = self
//        return cell
//    }
//    
//    private func prepareSwitchTableViewCell(_ dequeuedCell: UITableViewCell?, for row: SettingsViewModelV2.SwitchRow) -> UITableViewCell {
//        guard let cell = dequeuedCell as? SettingSwitchTableViewCell else {
//            Log.shared.errorAndCrash("Invalid state.")
//            return UITableViewCell()
//        }
//        cell.textLabel?.text = row.title
//        cell.textLabel?.textColor = viewModelv2.titleColor(rowIdentifier: row.identifier)
//        cell.viewModel = settingSwitchViewModel
//        cell.setUpView()
//        return cell
//    }
//}
//
//// MARK: - Navigation
//
//extension SettingsTableViewController: SegueHandlerType {
//    enum SegueIdentifier: String {
//        case segueAddNewAccount
//        case segueEditAccount
//        case segueShowSettingDefaultAccount
//        case sequeShowCredits
//        case segueShowSettingTrustedServers
//        case segueExtraKeys
//        case segueSetOwnKey
//        case seguePerAccountSync
//        case noAccounts
//        case ResetTrustSplitView
//        case ResetTrust
//        case noSegue
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        switch segueIdentifier(for: segue) {
//        case .segueEditAccount:
//            guard
//                let nav = segue.destination as? UINavigationController,
//                let destination = nav.topViewController as? AccountSettingsTableViewController
//                else {
//                    return
//            }
//            destination.appConfig = appConfig
//            if let path = ipath ,
//                let vm = viewModelv1[path.section][path.row] as? SettingsCellViewModel,
//                let acc = vm.account  {
//                    destination.viewModel = AccountSettingsViewModel(account: acc)
//            }
//        case .ResetTrustSplitView:
//            guard
//            let nav = segue.destination as? UINavigationController,
//            let destination = nav.topViewController as? BaseTableViewController
//            else {
//                return
//            }
//            destination.appConfig = self.appConfig
//        case .noAccounts,
//             .segueAddNewAccount,
//             .sequeShowCredits,
//             .ResetTrust,
//             .segueExtraKeys,
//             .seguePerAccountSync:
//            guard let destination = segue.destination as? BaseViewController else {
//                return
//            }
//            destination.appConfig = self.appConfig
//        case .segueShowSettingDefaultAccount,
//             .segueShowSettingTrustedServers:
//            guard let destination = segue.destination as? BaseTableViewController else {
//                return
//            }
//            destination.appConfig = self.appConfig
//        case .segueSetOwnKey:
//            break
//        case .noSegue:
//            // does not need preperation
//            break
//        }
//    }
//}
//
//// MARK: - Private
//
//extension SettingsTableViewController {
//    private func handleResetAllIdentity() {
//        let title = NSLocalizedString("Reset All Identities", comment: "Settings confirm to reset all identity title alert")
//        let message = NSLocalizedString("This action will reset all your identities. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")
//
//        guard let pepAlertViewController =
//            PEPAlertViewController.fromStoryboard(title: title,
//                                                  message: message,
//                                                  paintPEPInTitle: true) else {
//                                                    Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
//                                                    return
//        }
//
//        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
//        let cancelAction = PEPUIAlertAction(title: cancelTitle,
//                                            style: .pEpGray) { _ in
//                                                pepAlertViewController.dismiss(animated: true,
//                                                                               completion: nil)
//        }
//        pepAlertViewController.add(action: cancelAction)
//        
//        let resetTitle = NSLocalizedString("Reset All", comment: "Reset account identity button title")
//        let resetAction = PEPUIAlertAction(title: resetTitle,
//                                           style: .pEpRed,
//                                           handler: { [weak self] _ in
//                                            pepAlertViewController.dismiss(animated: true,
//                                                                           completion: nil)
//                                            self?.viewModelv2.handleResetAllIdentities()
//        })
//        pepAlertViewController.add(action: resetAction)
//
//        pepAlertViewController.modalPresentationStyle = .overFullScreen
//        pepAlertViewController.modalTransitionStyle = .crossDissolve
//
//        DispatchQueue.main.async { [weak self] in
//            self?.present(pepAlertViewController, animated: true)
//        }
//    }
//
//    private func updateUI() {
//        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
//    }
//
//    private func deleteRowAt(_ indexPath: IndexPath) {
//        self.viewModelv1.delete(section: indexPath.section, cell: indexPath.row)
////
////        if let position =  navigationController?.viewControllers.count, let previousVc = navigationController?.viewControllers[position - 1] as? EmailViewController {
////            if viewModel.canBeShown(Message: previousVc.message) {
////                navigationController?.viewControllers.remove(at: position-1)
////            }
////        }
//        if self.viewModelv2.noAccounts() {
//            self.performSegue(withIdentifier: "noAccounts", sender: nil)
//        }
//    }
//
//    private func showAlertBeforeDelete(_ indexPath: IndexPath) {
//        let title = NSLocalizedString("Are you sure you want to delete the account?", comment: "Account delete confirmation")
//        let buttonTitle = NSLocalizedString("Delete", comment: "Delete account button title")
//        let deleteAction: (UIAlertAction) -> () = { [weak self] _ in
//            guard let me = self else {
//                Log.shared.lostMySelf()
//                return
//            }
//            me.deleteRowAt(indexPath)
//            me.tableView.beginUpdates()
//            if let pEpSyncSection = self?.viewModelv2.pEpSyncSection() {
//                me.tableView.reloadSections([pEpSyncSection], with: UITableView.RowAnimation.none)
//            }
//            me.tableView.deleteRows(at: [indexPath], with: .fade)
//            me.tableView.endUpdates()
//        }
//        showAlert(title, buttonTitle, deleteAction, indexPath)
//    }
//
//    private func showAlert(_ message: String,
//                           _ confirmButtonTitle: String,
//                           _ confirmButtonAction: @escaping ((UIAlertAction)->()),
//                           _ indexPath: IndexPath) {
//        tableView.cellForRow(at: indexPath)?.isSelected = false //!!!: bad. side effect in showAlert.
//        let alertController = UIAlertController.pEpAlertController(
//            title: nil,
//            message: message,
//            preferredStyle: .actionSheet)
//
//        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel title button")
//        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in }
//        alertController.addAction(cancelAction)
//
//        let destroyAction = UIAlertAction(title: confirmButtonTitle,
//                                          style: .destructive, handler: confirmButtonAction)
//        alertController.addAction(destroyAction)
//
//        if let popoverPresentationController = alertController.popoverPresentationController {
//            let cellFrame = tableView.rectForRow(at: indexPath)
//            let sourceRect = view.convert(cellFrame, from: tableView)
//            popoverPresentationController.sourceRect = sourceRect
//            popoverPresentationController.sourceView = view
//        }
//
//        self.present(alertController, animated: true) {
//        }
//    }
//}
//
//// MARK: - Extra Keys
//
//extension SettingsTableViewController {
//
//    /// Adds easter egg gesture to [en|dis]able the editability of extra keys
//    private func addExtraKeysEditabilityToggleGesture() {
//        let gestureRecogniser =
//            UITapGestureRecognizer(target: self,
//                                   action: #selector(extraKeysEditabilityToggleGestureTriggered))
//        gestureRecogniser.numberOfTapsRequired = 6
//        gestureRecogniser.numberOfTouchesRequired = 3
//        tableView.addGestureRecognizer(gestureRecogniser)
//    }
//
//    @objc // @objc is required for selector
//    private func extraKeysEditabilityToggleGestureTriggered() {
//        viewModelv1.handleExtryKeysEditabilityGestureTriggered()
//    }
//}
//
//// MARK: - SettingsViewModelDelegate
//
//extension SettingsTableViewController: SettingsViewModelDelegate {
//    func showLoadingView() {
//        DispatchQueue.main.async { [weak self] in
//            UIApplication.shared.beginIgnoringInteractionEvents()
//            self?.activityIndicatorView = self?.showActivityIndicator()
//        }
//    }
//    
//    func hideLoadingView() {
//        DispatchQueue.main.async { [weak self] in
//            UIApplication.shared.endIgnoringInteractionEvents()
//            self?.activityIndicatorView?.removeFromSuperview()
//        }
//    }
//
//    func showExtraKeyEditabilityStateChangeAlert(newValue: String) {
//        UIUtils.showAlertWithOnlyPositiveButton(title: "Extra Keys Editable",
//                                                message: newValue,
//                                                inViewController: self)
//    }
//}
//
//extension SettingsTableViewController: keySyncActionsProtocol {
//
//    func updateSyncStatus(to value: Bool) {
//        if viewModel.isGrouped {
//            let title = NSLocalizedString("Disable p≡p Sync",
//                                          comment: "Leave device group confirmation")
//            let comment = NSLocalizedString("If you disable p≡p Sync, your device group will be dissolved. Are you sure you want to disable disable p≡p Sync?",
//                                            comment: "Leave device group confirmation comment")
//
//            let alert = UIAlertController.pEpAlertController(title: title,
//                                                             message: comment, preferredStyle: .alert)
//            let cancelAction = alert.action(NSLocalizedString("Cancel",
//                                                              comment: "keysync alert leave device group cancel"),
//                                            .cancel) { [weak self] in
//                guard let me = self else {
//                    Log.shared.errorAndCrash(message: "lost myself")
//                    return
//                }
//                me.tableView.reloadData()
//            }
//            let disableAction = alert.action("Disable", .default) { [weak self] in
//                guard let me = self else {
//                    Log.shared.errorAndCrash(message: "lost myself")
//                    return
//                }
//                me.viewModel.pEpSyncUpdate(to: value)
//            }
//            alert.addAction(cancelAction)
//            alert.addAction(disableAction)
//            present(alert, animated: true)
//        } else {
//            viewModel.pEpSyncUpdate(to: value)
//        }
//    }
//}
