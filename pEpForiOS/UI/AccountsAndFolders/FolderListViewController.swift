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

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: standardCell)

        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refreshFoldersControl),
                                    forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshController
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepareFetchRequest()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func prepareFetchRequest() {
        let fetchRequest = NSFetchRequest.init(entityName: Folder.entityName())

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

    func refreshFoldersControl(refreshControl: UIRefreshControl? = nil) {
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
        UIApplication.sharedApplication().networkActivityIndicatorVisible = state.isUpdating
        if !state.isUpdating {
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            standardCell, forIndexPath: indexPath)
        configureCell(cell, indexPath: indexPath)
        return cell
    }

    override func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        if let folder = fetchController?.objectAtIndexPath(indexPath) as? Folder {
            cell.textLabel?.text = "\(folder.name)"
            cell.accessoryType = .DisclosureIndicator
        }
    }

    override func tableView(tableView: UITableView,
                            canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let folder = fetchController?.objectAtIndexPath(indexPath) as? Folder {
            switch folder.folderType.integerValue {
            case FolderType.LocalOutbox.rawValue, FolderType.Inbox.rawValue: return false
            default: return true
            }
        }
        return false
    }

    override func tableView(
        tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
        if let folder = fetchController?.objectAtIndexPath(indexPath) as? Folder {
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
        tableView: UITableView,
        indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        if var folder = fetchController?.objectAtIndexPath(indexPath) as? Folder {
            var count = 0
            while folder.parent != nil {
                count += 1
                folder = folder.parent!
            }
            return count
        }
        return 0
    }

    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let fi = fetchController?.objectAtIndexPath(indexPath) as? Folder {
            let predicateBasic = config.appConfig.model.basicMessagePredicate()
            let predicateAccount = NSPredicate.init(
                format: "folder.account.email = %@", config.account.email)
            let predicateFolder = NSPredicate.init(
                format: "folder.name = %@", fi.name)

            // If the folder is just local, then don't let the email list view sync.
            var account: IAccount? = nil
            if let ft = FolderType.fromInt(fi.folderType.integerValue) {
                if ft.isRemote() {
                    account = config.account
                }
                // Start syncing emails when it's not an inbox (which was just synced already)
                let syncOnAppear = ft != .Inbox

                emailListConfig = EmailListViewController.EmailListConfig.init(
                    appConfig: config.appConfig,
                    predicate: NSCompoundPredicate.init(
                        andPredicateWithSubpredicates: [predicateBasic, predicateAccount,
                            predicateFolder]),
                    sortDescriptors: [NSSortDescriptor.init(
                        key: "receivedDate", ascending: false)],
                    account: account, folderName: fi.name, syncOnAppear: syncOnAppear)

                performSegueWithIdentifier(segueShowEmails, sender: self)
            }
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueShowEmails {
            guard let vc = segue.destinationViewController as?
                EmailListViewController else {
                return
            }
            vc.config = emailListConfig
        }
    }
}