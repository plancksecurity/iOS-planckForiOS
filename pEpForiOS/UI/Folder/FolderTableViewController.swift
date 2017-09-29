//
//  FolderTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 16/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class FolderTableViewController: BaseTableViewController {
    var folderVM = FolderViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfig()
    }
    
    func initialConfig() {
        self.title = NSLocalizedString("Folders", comment: "FolderView")
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 80.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        let item = UIBarButtonItem(title: "Settings", style: .plain, target: self,
                                   action: #selector(settingsTapped))
        navigationItem.rightBarButtonItem = item
    }

    @objc func settingsTapped() {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return folderVM.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderVM[section].count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header :CollapsibleTableViewHeader?
        if let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            as? CollapsibleTableViewHeader{
            header = head
        } else {
            header = CollapsibleTableViewHeader(reuseIdentifier: "header")
        }
        header!.configure(viewModel: folderVM[section], section: section)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        let fcvm = folderVM[indexPath.section][indexPath.item]
        cell.detailTextLabel?.text = "\(fcvm.number)"
        cell.textLabel?.text = fcvm.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath)
        -> Int {
        return folderVM[indexPath.section][indexPath.item].level
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard
            let vc = sb.instantiateViewController(withIdentifier: EmailListViewController.storyboardId)
                as? EmailListViewController_IOS700
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
                return
        }

        vc.appConfig = appConfig
        //BUFF:
//        let config = EmailListConfig(appConfig: appConfig,
//                                     folder: folderVM[indexPath.section][indexPath.row]
//                                        .getFolder())
//        vc.config = config
        vc.folderToShow = folderVM[indexPath.section][indexPath.row].getFolder()
        vc.hidesBottomBarWhenPushed = false
        self.navigationController?.pushViewController(vc, animated: true)
    }

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
