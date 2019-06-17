//
//  SettingsTableViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import SwipeCellKit
import pEpIOSToolbox

class SettingsTableViewController: BaseTableViewController, SwipeTableViewCellDelegate {
    static let storyboardId = "SettingsTableViewController"
    let viewModel = SettingsViewModel()
    var settingSwitchViewModel: SwitchSettingCellViewModelProtocol?

    var ipath : IndexPath?

    struct UIState {
        var isSynching = false
    }

    var state = UIState()

    var oldToolbarStatus : Bool = true

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "Settings view title")
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController {
            oldToolbarStatus = nc.isToolbarHidden
        }
        self.navigationController?.setToolbarHidden(true, animated: false)

        if MiscUtil.isUnitTest() {
            super.viewWillAppear(animated)
            return
        }
        updateModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(oldToolbarStatus, animated: false)
        guard let isIphone = splitViewController?.isCollapsed else {
            return
        }
        if !isIphone {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let detailViewController = storyBoard.instantiateViewController(withIdentifier: "noMessagesViewController") as! NoMessagesViewController
            self.splitViewController?.show(detailViewController, sender: nil)
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  viewModel[section].count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return viewModel[section].title
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel[section].footer
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier:
            viewModel[indexPath.section][indexPath.row].cellIdentifier, for: indexPath)

        let vm = viewModel[indexPath.section][indexPath.row]
        if isRepresentingOnOffSwichSetting(viewModel: vm) {
            guard
                let vm = viewModel[indexPath.section][indexPath.row]
                    as? SwitchSettingCellViewModelProtocol,
                let cell = dequeuedCell as? SettingSwitchTableViewCell
                else {
                    return dequeuedCell
            }
            cell.viewModel = vm
            cell.setUpView()
            cell.selectionStyle = .none
            return cell
        } else {
            guard
                let vm = viewModel[indexPath.section][indexPath.row] as? SettingsCellViewModel,
                let cell = dequeuedCell as? SwipeTableViewCell else {
                    Log.shared.errorAndCrash("Invalid state.")
                    return dequeuedCell
            }
            cell.textLabel?.text = vm.title
            cell.detailTextLabel?.text = vm.detail
            if vm.disclousureIndicator {
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }
            cell.delegate = self
            return cell
        }
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if indexPath.section == 0 {
            let deleteAction = SwipeAction(style: .destructive, title: "Delete") {
                [weak self] action, indexPath in
                    guard let me = self else {
                        Log.shared.lostMySelf()
                        return
                    }
                    self?.showAlertBeforeDelete(indexPath)
            }
            return (orientation == .right ?   [deleteAction] : nil)
        }

        return nil
    }

    func tableView(_ tableView: UITableView,
                   editActionsOptionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = .none
        options.transitionStyle = .border
        return options
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let rowType = viewModel.rowType(for: indexPath) else {
            // Nothing to do here. Its a simple On/Off switch cell. No need to segue anywhere.
            return
        }
        switch rowType {
        case .account:
            self.ipath = indexPath
            performSegue(withIdentifier: .segueEditAccount, sender: self)
        case .defaultAccount:
            performSegue(withIdentifier: .segueShowSettingDefaultAccount, sender: self)
        case .showLog:
            performSegue(withIdentifier: .segueShowLog, sender: self)
        case .credits:
            performSegue(withIdentifier: .sequeShowCredits, sender: self)
        case .trustedServer:
            performSegue(withIdentifier: .segueShowSettingTrustedServers, sender: self)
        case .setOwnKey:
            performSegue(withIdentifier: .segueSetOwnKey, sender: self)
        case .leaveKeySyncGroup:
            showAlertBeforeLeavingDeviceGroup(indexPath)
        }
    }
}

// MARK: - Navigation

extension SettingsTableViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case segueAddNewAccount
        case segueEditAccount
        case segueShowSettingDefaultAccount
        case segueShowLog
        case sequeShowCredits
        case segueShowSettingTrustedServers
        case segueSetOwnKey
        case noAccounts
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueEditAccount:
            guard
                let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? AccountSettingsTableViewController
                else {
                    return
            }
            destination.appConfig = self.appConfig
            if let path = ipath ,
                let vm = viewModel[path.section][path.row] as? SettingsCellViewModel,
                let acc = vm.account  {
                    let vm = AccountSettingsViewModel(account: acc)
                    destination.viewModel = vm
            }
        case .noAccounts,
             .segueAddNewAccount,
             .sequeShowCredits:
            guard let destination = segue.destination as? BaseViewController else {
                return
            }
            destination.appConfig = self.appConfig
        case .segueShowSettingDefaultAccount,
             .segueShowSettingTrustedServers:
            guard let destination = segue.destination as? BaseTableViewController else {
                return
            }
            destination.appConfig = self.appConfig
        case .segueShowLog:
            guard let viewController = segue.destination as? LogViewController else {
                    return
            }
            viewController.appConfig = self.appConfig
        case .segueSetOwnKey:
            break
        case .noSegue:
            // does not need preperation
            break
        }
    }
}

// MARK: - Private
extension SettingsTableViewController {
    private func updateModel() {
        //reload data in view model
        tableView.reloadData()
    }

    private func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
    }

    private func isRepresentingOnOffSwichSetting(viewModel: SettingCellViewModelProtocol) -> Bool {
        return (viewModel as? SwitchSettingCellViewModelProtocol != nil) ? true : false
    }

    private func deleteRowAt(_ indexPath: IndexPath) {
        self.viewModel.delete(section: indexPath.section, cell: indexPath.row)

        if let position =  navigationController?.viewControllers.count, let previousVc = navigationController?.viewControllers[position - 1] as? EmailViewController {
            if viewModel.canBeShown(Message: previousVc.message) {
                navigationController?.viewControllers.remove(at: position-1)
            }
        }
        if self.viewModel.noAccounts() {
            self.performSegue(withIdentifier: "noAccounts", sender: nil)
        }
    }

    private func showAlertBeforeLeavingDeviceGroup(_ indexPath: IndexPath) {
        let title = "Are you sure you want to leave your device group?"
        let comment = "leaving device group"
        let buttonTitle = "Leave"
        let leavingAction: (UIAlertAction)-> () = { [weak self] _ in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            do {
                try KeySyncDeviceGroupService().leaveDeviceGroup()
            } catch {
                Log.shared.errorAndCrash("%@", error.localizedDescription)
            }
        }
        showAlert(title, comment, buttonTitle, leavingAction, indexPath)
    }

    private func showAlertBeforeDelete(_ indexPath: IndexPath) {
        let title = "Are you sure you want to delete the account?"
        let comment = "delete account message"
        let buttonTitle = "Delete"
        let deleteAction: (UIAlertAction) -> () = { [weak self] _ in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.deleteRowAt(indexPath)
            me.tableView.beginUpdates()
            me.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            me.tableView.endUpdates()}
        showAlert(title, comment, buttonTitle, deleteAction, indexPath)
    }

    private func showAlert(_ message: String,_ comment: String,
                           _ confirmButtonTittle: String,
                           _ confirmButtonAction: @escaping ((UIAlertAction)->()),
                           _ indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        let alertController = UIAlertController.pEpAlertController(
            title: nil,
            message: NSLocalizedString(message, comment: comment), preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: confirmButtonTittle,
                                          style: .destructive, handler: confirmButtonAction)
        alertController.addAction(destroyAction)

        if let popoverPresentationController = alertController.popoverPresentationController {
            let cellFrame = tableView.rectForRow(at: indexPath)
            let sourceRect = view.convert(cellFrame, from: tableView)
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.sourceView = view
        }

        self.present(alertController, animated: true) {
        }
    }
}
