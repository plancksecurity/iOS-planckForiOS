//
//  FolderTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 16/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class FolderTableViewController: BaseTableViewController {
    var folderVM: FolderViewModel?
    var showNext: Bool = true

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfig()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        if showNext {
            showFolder(indexPath: nil)
        }
        self.navigationController?.setToolbarHidden(false, animated: false)
    }

    // MARK: - Setup

    private func setup() {
        DispatchQueue.main.async {
            self.folderVM =  FolderViewModel()
            self.tableView.reloadData()
        }
    }
    
    private func initialConfig() {
        self.title = NSLocalizedString("Folders", comment: "FoldersView")
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 80.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        let item = UIBarButtonItem.getPEPButton(
            action:#selector(showSettingsViewController),
            target: self)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
            target: nil,
            action: nil)
        self.toolbarItems = [flexibleSpace,item]
    }

    // MARK: - Action

    @objc private func showSettingsViewController() {
        UIUtils.presentSettings(on: self, appConfig: appConfig)
    }

    // MARK: - Cell Setup

    private func setNotSelectableStyle(to cell: UITableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.textColor = UIColor.pEpGray
    }

    private func setSelectableStyle(to cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = UIColor.black
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return folderVM?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderVM?[section].count ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        let header :CollapsibleTableViewHeader?
        if let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            as? CollapsibleTableViewHeader{
            header = head
        } else {
            header = CollapsibleTableViewHeader(reuseIdentifier: "header")
        }
        guard let vm = folderVM, let safeHeader = header else {
            Log.shared.errorAndCrash(component: #function, errorString: "No header or no model.")
            return header
        }

        if vm[section].hidden {
            return nil
        }


        safeHeader.configure(viewModel: vm[section], section: section)
        return header
    }

    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model.")
            return 0.0
        }
        if vm[section].hidden {
            return 0.0
        } else {
            return tableView.sectionHeaderHeight
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        guard let vm = folderVM else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return cell
        }
        let fcvm = vm[indexPath.section][indexPath.item]
        cell.textLabel?.text = fcvm.title
        cell.imageView?.image = fcvm.image

        if fcvm.isSelectable {
            setSelectableStyle(to: cell)
        } else {
            setNotSelectableStyle(to: cell)
        }
        cell.indentationWidth = 20.0
        return cell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath)
        -> Int {
            guard let vm = folderVM else {
                Log.shared.errorAndCrash(component: #function, errorString: "No model")
                return 0
            }
        return vm[indexPath.section][indexPath.item].level - 1
    }

    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let folderViewModel = folderVM else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return
        }
        let cellViewModel = folderViewModel[indexPath.section][indexPath.row]
        if !cellViewModel.isSelectable {
            // Me must not open unselectable folders. Unselectable folders are typically path
            // components/nodes that can not hold messages.
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        showFolder(indexPath: indexPath)
    }

    private func showFolder(indexPath: IndexPath?) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard
            let vc = sb.instantiateViewController(
                withIdentifier: EmailListViewController.storyboardId)
                as? EmailListViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
                    return
        }
        vc.appConfig = appConfig
        let emailListViewModel =
            folderVM?.createEmailListViewModel(forAccountAt: indexPath?.section,
                                               andFolderAt: indexPath?.row,
                                               messageSyncService: appConfig.messageSyncService)
        vc.model = emailListViewModel
        vc.hidesBottomBarWhenPushed = false

        let animated =  showNext ? false : true
        showNext = false
        self.navigationController?.pushViewController(vc, animated: animated)
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newAccountIphone"
            || segue.identifier == "newAccountIpad"{
            guard
                let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? LoginViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Missing VCs")
                    return
            }
            vc.appConfig = self.appConfig
            vc.hidesBottomBarWhenPushed = true
            vc.delegate = self

        } else if segue.identifier == "SettingsSegue" {
            guard let dvc = segue.destination as? SettingsTableViewController else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error casting DVC")
                return
            }
            dvc.appConfig = self.appConfig
            dvc.hidesBottomBarWhenPushed = true
        }
    }

    @IBAction func addAccountTapped(_ sender: Any) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            performSegue(withIdentifier: "newAccountIpad", sender: self)
        } else {
            performSegue(withIdentifier: "newAccountIphone", sender: self)
        }
    }

    /**
     Unwind segue for the case of adding an account that requires manual setup
     */
    @IBAction func segueUnwindAfterAccountCreation(segue:UIStoryboardSegue) {
        showNext = true
    }
}

// MARK: - LoginTableViewControllerDelegate

extension FolderTableViewController: LoginViewControllerDelegate {
    func loginViewControllerDidCreateNewAccount(
        _ loginViewController: LoginViewController) {
        setup()
        showNext = true
    }
}
