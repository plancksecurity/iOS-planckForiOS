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
        self.navigationController?.setToolbarHidden(true, animated: true)
        setup()
        if showNext {
            showFolder(indexPath: nil)
        }
    }

    // MARK: - Setup

    private func setup() {
        //ViewModel init
        DispatchQueue.main.async {
            self.folderVM =  FolderViewModel()
            self.tableView.reloadData()
        }
    }
    
    private func initialConfig() {
        self.title = NSLocalizedString("Folders", comment: "FolderView")
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 80.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        let item = UIBarButtonItem(title: "Settings", style: .plain, target: self,
                                   action: #selector(settingsTapped))
        navigationItem.rightBarButtonItem = item
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

    // MARK: - Actions

    @objc func settingsTapped() {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
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

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        guard let vm = folderVM else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return cell
        }
        let fcvm = vm[indexPath.section][indexPath.item]
        cell.textLabel?.text = fcvm.title
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
            let vc = sb.instantiateViewController(withIdentifier: EmailListViewController.storyboardId)
                as? EmailListViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
                return
        }
        vc.appConfig = appConfig
        if let vm = folderVM, let ip = indexPath {
            vc.folderToShow = vm[ip.section][ip.row].folder
        }
        vc.hidesBottomBarWhenPushed = false

        let animated =  showNext ? false : true
        showNext = false
        self.navigationController?.pushViewController(vc, animated: animated)
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newAccount" {
            guard
                let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? LoginTableViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Missing VCs")
                    return
            }
            vc.appConfig = self.appConfig
            vc.hidesBottomBarWhenPushed = true
            vc.delegate = self

        } else if segue.identifier == "SettingsSegue" {
            guard let dvc = segue.destination as? AccountsTableViewController else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error casting DVC")
                return
            }
            dvc.appConfig = self.appConfig
            dvc.hidesBottomBarWhenPushed = true
        }
    }
}

// MARK: - LoginTableViewControllerDelegate

extension FolderTableViewController: LoginTableViewControllerDelegate {
    func loginTableViewControllerDidCreateNewAccount(
        _ loginTableViewController: LoginTableViewController) {
        showNext = true
    }
}
