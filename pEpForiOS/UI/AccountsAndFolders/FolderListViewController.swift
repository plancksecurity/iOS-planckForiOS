//
//  FolderListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

class FolderListViewController: FetchTableViewController {
    struct FolderListConfig {
        let account: IAccount
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

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: standardCell)

        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refreshFoldersControl),
                                    for: UIControlEvents.valueChanged)
        self.refreshControl = refreshController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareFetchRequest()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func prepareFetchRequest() {
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: Folder.entityName())

        let predicateAccount = NSPredicate.init(
            format: "account.email = %@", config.account.email)
        let predicateNotDeleted = NSPredicate.init(
            format: "shouldDelete = false")
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: [predicateAccount, predicateNotDeleted])

        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "name", ascending: true)]
        fetchController = NSFetchedResultsController.init(
            fetchRequest: fetchRequest,
            managedObjectContext: config.appConfig.coreDataUtil.managedObjectContext,
            sectionNameKeyPath: nil, cacheName: nil)
        fetchController?.delegate = self
        do {
            try fetchController?.performFetch()
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
    }

    func refreshFoldersControl(_ refreshControl: UIRefreshControl? = nil) {
        state.isUpdating = true
        updateUI()
        config.appConfig.grandOperator.fetchFolders(
            config.account.connectInfo, completionBlock: { error in
                self.state.isUpdating = false
                self.updateUI()
                self.tableView.reloadData()
        })
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

    override func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        if let folder = fetchController?.object(at: indexPath) as? Folder {
            cell.textLabel?.text = "\(folder.name)"
            cell.accessoryType = .disclosureIndicator
        }
    }

    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        if let folder = fetchController?.object(at: indexPath) as? Folder {
            switch folder.folderType.intValue {
            case FolderType.localOutbox.rawValue, FolderType.inbox.rawValue: return false
            default: return true
            }
        }
        return false
    }

    override func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath) {
        if let folder = fetchController?.object(at: indexPath) as? Folder {
            folder.shouldDelete = true
            config.appConfig.model.save()
            state.isUpdating = true
            updateUI()

            config.appConfig.grandOperator.deleteFolder(folder as IFolder) { error in
                UIHelper.displayError(error, controller: self)
                self.state.isUpdating = false
                self.updateUI()
            }
        }
    }

    // MARK: - Table view delegate

    override func tableView(
        _ tableView: UITableView,
        indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if var folder = fetchController?.object(at: indexPath) as? Folder {
            var count = 0
            while folder.parent != nil {
                count += 1
                folder = folder.parent!
            }
            return count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if let fi = fetchController?.object(at: indexPath) as? Folder {
            let predicateBasic = config.appConfig.model.basicMessagePredicate()
            let predicateAccount = NSPredicate.init(
                format: "folder.account.email = %@", config.account.email)
            let predicateFolder = NSPredicate.init(
                format: "folder.name = %@", fi.name)

            // If the folder is just local, then don't let the email list view sync.
            var account: IAccount? = nil
            if let ft = FolderType.fromInt(fi.folderType.intValue) {
                if ft.isRemote() {
                    account = config.account
                }
                // Start syncing emails when it's not an inbox (which was just synced already)
                let syncOnAppear = ft != .inbox

                emailListConfig = EmailListViewController.EmailListConfig.init(
                    appConfig: config.appConfig,
                    predicate: NSCompoundPredicate.init(
                        andPredicateWithSubpredicates: [predicateBasic, predicateAccount,
                            predicateFolder]),
                    sortDescriptors: [NSSortDescriptor.init(
                        key: "receivedDate", ascending: false)],
                    account: account, folderName: fi.name, syncOnAppear: syncOnAppear)

                performSegue(withIdentifier: segueShowEmails, sender: self)
            }
        }
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
