//
//  FolderListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class FolderListViewController: UITableViewController {
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

    var folderItems: [FolderModelOperation.FolderItem] = []

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
        updateModelFromDataBase()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateModelFromDataBase() {
        let op = FolderModelOperation.init(
            account: config.account, coreDataUtil: config.appConfig.coreDataUtil)
        op.completionBlock = {
            GCD.onMain() {
                self.folderItems = op.folderItems
                self.tableView.reloadData()
            }
        }
        op.start()
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
        if state.isUpdating {
            self.refreshControl?.beginRefreshing()
        } else {
            self.refreshControl?.endRefreshing()
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = state.isUpdating
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(
        tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            standardCell, forIndexPath: indexPath)

        let fi = folderItems[indexPath.row]
        if fi.numberOfMessages > 0 {
            cell.textLabel?.text = "\(fi.name) (\(fi.numberOfMessages))"
        } else {
            cell.textLabel?.text = fi.name
        }
        cell.accessoryType = .DisclosureIndicator

        return cell
    }

    override func tableView(tableView: UITableView,
                            canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let fi = folderItems[indexPath.row]
        switch fi.type {
            case .LocalOutbox, .Inbox: return false
            default: return true
        }
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let fi = folderItems[indexPath.row]
        let folder = config.appConfig.coreDataUtil.managedObjectContext.objectWithID(
            fi.objectID)
        config.appConfig.grandOperator.deleteFolder(folder as! IFolder) { error in
            UIHelper.displayError(error, controller: self)
            self.state.isUpdating = false
            self.updateUI()
        }
        folderItems.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }

    // MARK: - Table view delegate

    override func tableView(
        tableView: UITableView,
        indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        let fi = folderItems[indexPath.row]
        return fi.level
    }

    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let fi = folderItems[indexPath.row]

        let predicateBasic = config.appConfig.model.basicMessagePredicate()
        let predicateAccount = NSPredicate.init(
            format: "folder.account.email = %@", config.account.email)
        let predicateFolder = NSPredicate.init(
            format: "folder.name = %@", fi.name)

        // If the folder is just local, then don't let the email list view sync.
        var account: IAccount? = nil
        if fi.type.isRemote() {
            account = config.account
        }

        // Start syncing emails when it's not an inbox (which was just synced already)
        let syncOnAppear = fi.type != .Inbox

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