//
//  FolderListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

class FolderListViewController: UITableViewController {
    let comp = "FolderListViewController"

    struct FolderListConfig {
        let account: Account
        let appConfig: AppConfig
    }

    var emailListConfig: EmailListViewController.EmailListConfig? = nil

    /** Our vanilla table view cell */
    let standardCell = "standardCell"

    /** The segue to the email list view for a folder. */
    let segueShowEmails = "segueShowEmails"

    var config: FolderListConfig!

    struct UIState {
        var isUpdating = false
    }

    var state = UIState()

    var folders = [Folder]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: standardCell)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateModel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateModel() {
        folders = config.account.rootFolders
    }

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isUpdating
        if !state.isUpdating {
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: standardCell, for: indexPath)
        configureCell(cell, indexPath: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let folder = folderAt(indexPath: indexPath)
        cell.textLabel?.text = "\(folder.name)"
        cell.accessoryType = .disclosureIndicator
    }

    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        let folder = folderAt(indexPath: indexPath)
        switch folder.folderType {
        case FolderType.localOutbox, FolderType.inbox: return false
        default: return true
        }
    }

    override func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath) {
        let folder = folderAt(indexPath: indexPath)
        folder.delete()
    }

    func folderAt(indexPath: IndexPath) -> Folder {
        return folders[indexPath.row]
    }

    // MARK: - Table view delegate

    override func tableView(
        _ tableView: UITableView,
        indentationLevelForRowAt indexPath: IndexPath) -> Int {
        var folder = folderAt(indexPath: indexPath) as MessageFolder
        var count = 0
        while folder.parent != nil {
            count += 1
            folder = folder.parent!
        }
        return count
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        let fi = folderAt(indexPath: indexPath)
        emailListConfig = EmailListViewController.EmailListConfig.init(
            appConfig: config.appConfig,
            account: config.account, folder: fi)

        performSegue(withIdentifier: segueShowEmails, sender: self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueShowEmails {
            guard let vc = segue.destination as?
                EmailListViewController else {
                return
            }
            vc.config = emailListConfig
        }
    }
}
