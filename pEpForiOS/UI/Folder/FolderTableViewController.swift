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

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfig()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
        setupViewModel()
    }

    // MARK: - Setup

    private func setupViewModel() {
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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

        safeHeader.configure(viewModel: vm[section], section: section)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        guard let vm = folderVM else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return cell
        }
        let fcvm = vm[indexPath.section][indexPath.item]
        cell.detailTextLabel?.text = "\(fcvm.number)"
        cell.textLabel?.text = fcvm.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath)
        -> Int {
            guard let vm = folderVM else {
                Log.shared.errorAndCrash(component: #function, errorString: "No model")
                return 0
            }
        return vm[indexPath.section][indexPath.item].level
    }

    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard
            let vc = sb.instantiateViewController(withIdentifier: EmailListViewController.storyboardId)
                as? EmailListViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
                return
        }

        vc.appConfig = appConfig
        guard let vm = folderVM else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return
        }
        vc.folderToShow = vm[indexPath.section][indexPath.row].folder
        vc.hidesBottomBarWhenPushed = false
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newAccount" {
            if let vc = segue.destination as? LoginTableViewController {
                vc.appConfig = self.appConfig
                vc.hidesBottomBarWhenPushed = true
            }
        } else if segue.identifier == "SettingsSegue" {
            guard let dnc = segue.destination as? UINavigationController,
                let dvc = dnc.rootViewController as? AccountsTableViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Error casting DVC")
                    return
            }
            dvc.appConfig = self.appConfig
            dvc.hidesBottomBarWhenPushed = true
        }
    }
}
