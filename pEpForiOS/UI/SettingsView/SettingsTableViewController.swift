//
//  SettingsTableViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import SwipeCellKit

class SettingsTableViewController: BaseTableViewController, SwipeTableViewCellDelegate {
    static let storyboardId = "SettingsTableViewController"
    let viewModel = SettingsViewModel()
    var settingSwitchViewModel: SwitchSettingCellViewModelProtocol?

    /** Our vanilla table view cell */
    let accountsCellIdentifier = "accountsCell"

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
    }

    // MARK: - Internal

    private func updateModel() {
        //reload data in view model
        tableView.reloadData()
    }

    private func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
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
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state.")
                    return dequeuedCell
            }
            cell.textLabel?.text = vm.title
            cell.detailTextLabel?.text = vm.detail
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            cell.delegate = self
            return cell
        }
    }

    private func isRepresentingOnOffSwichSetting(viewModel: SettingCellViewModelProtocol) -> Bool {
        return (viewModel as? SwitchSettingCellViewModelProtocol != nil) ? true : false
    }

    private func deleteRowAt(_ indexPath: IndexPath) {
        self.viewModel.delete(section: indexPath.section, cell: indexPath.row)
        if self.viewModel.noAccounts() {
            self.performSegue(withIdentifier: "noAccounts", sender: nil)
        }
    }

    private func showAlertBeforeDelete(_ indexPath: IndexPath) {
        let alertController = UIAlertController.pEpAlertController(
            title: nil,
            message: NSLocalizedString("Are you sure you want to delete the account?",
                                       comment:
                "delete account message"), preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
        }
        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteRowAt(indexPath)
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            self.tableView.endUpdates()
        }
        alertController.addAction(destroyAction)

        if let popoverPresentationController = alertController.popoverPresentationController {

            let cellFrame = tableView.rectForRow(at: indexPath)
            let sourceRect = self.view.convert(cellFrame, from: tableView)
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.sourceView = self.view
        }

        self.present(alertController, animated: true) {
        }
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if indexPath.section == 0 {
            let deleteAction = SwipeAction(style: .destructive,
                                           title: "Delete") { action, indexPath in
                                            self.showAlertBeforeDelete(indexPath)
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
        case noAccounts
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueEditAccount:
            guard
                let destination = segue.destination as? AccountSettingsTableViewController
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
        case .noSegue:
            // does not need preperation
            break
        }
    }
}
