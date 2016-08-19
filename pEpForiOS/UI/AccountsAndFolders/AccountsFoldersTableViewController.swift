//
//  AccountsFoldersTableViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountsFoldersTableViewController: UITableViewController {
    struct UIState {
        var isSynching: Bool {
            return accountsSyncing.count > 0
        }
        var accountsSyncing = NSMutableSet()
    }

    let comp = "AccountsFoldersTableViewController"

    /** Segue to the new account setup */
    let segueSetupNewAccount = "segueSetupNewAccount"

    /** The segue to the `EmailListViewController` */
    let segueEmailList = "segueEmailList"

    /** Our vanilla table view cell */
    let standardCell = "standardCell"

    /** The index of the section where important folders are listed */
    let folderSection = 0

    var appConfig: AppConfig?
    var accounts = [IAccount]()

    /** For email list configuration */
    var emailListConfig: EmailListConfig?

    /** For starting mySelf() */
    var backgroundQueue = NSOperationQueue.init()

    /** When this view is first shown, it will fetch folders as well. */
    var shouldFetchFolders = true

    var state = UIState.init()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: standardCell)

        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refresh(_:)),
                                    forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshController

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        if appConfig == nil {
            guard let appDelegate = UIApplication.sharedApplication().delegate as?
                AppDelegate else {
                    super.viewWillAppear(animated)
                    return
            }
            appConfig = appDelegate.appConfig
        }

        guard let ac = appConfig else {
            super.viewWillAppear(animated)
            return
        }

        let model = ac.model
        accounts.removeAll()
        if let allAccounts = model.accountsByPredicate(
            NSPredicate.init(value: true),
            sortDescriptors: [NSSortDescriptor.init(key: "email", ascending: true)]) {
            accounts.appendContentsOf(allAccounts)
        }

        if accounts.isEmpty {
            self.performSegueWithIdentifier(segueSetupNewAccount, sender: self)
        } else {
            doMyself()
        }
        refreshMailsControl()
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func doMyself() {
        guard let model = appConfig?.model else {
            return
        }
        if let accounts = model.accountsByPredicate(NSPredicate.init(
            value: true), sortDescriptors: nil) {
            for acc in accounts {
                let op = PEPMyselfOperation.init(account: acc)
                backgroundQueue.addOperation(op)
            }
        }
    }

    func refresh(refreshControl: UIRefreshControl) {
        refreshMailsControl(refreshControl)
    }

    func refreshMailsControl(refreshControl: UIRefreshControl? = nil) {
        guard let ac = appConfig else {
            return
        }

        if state.isSynching {
            return
        }

        for account in accounts {
            let connectInfo = account.connectInfo

            state.accountsSyncing.addObject(account)

            ac.grandOperator.fetchEmailsAndDecryptConnectInfo(
                connectInfo, folderName: nil, fetchFolders: shouldFetchFolders,
                completionBlock: { error in
                    Log.infoComponent(self.comp, "Sync completed, error: \(error)")
                    ac.model.save()
                    self.state.accountsSyncing.removeObject(account)
                    self.updateUI()
            })

            updateUI()
        }
        shouldFetchFolders = false
    }

    func updateUI() {
        if state.isSynching {
            self.refreshControl?.beginRefreshing()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(
        tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == folderSection {
            // Number of important folders to display, which at the moment
            // is equal to the number of accounts (number of inboxes)
            return accounts.count
        } else {
            return accounts.count
        }
    }

    override func tableView(
        tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == folderSection {
            return NSLocalizedString(
                "Folders", comment: "Section title for important folder list")
        } else {
            return NSLocalizedString(
                "Accounts", comment: "Section title for account list")
        }
    }

    override func tableView(
        tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == folderSection {
            let cell = tableView.dequeueReusableCellWithIdentifier(
                standardCell, forIndexPath: indexPath)

            let email = accounts[indexPath.row].email
            cell.textLabel?.text = String.init(
                format: NSLocalizedString(
                    "Inbox (%@)", comment: "Table view label for an inbox for an account"), email)
            cell.accessoryType = .DisclosureIndicator

            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(
                standardCell, forIndexPath: indexPath)

            cell.textLabel?.text = accounts[indexPath.row].email
            cell.accessoryType = .DisclosureIndicator

            return cell
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == folderSection {
            guard let ac = appConfig else {
                return
            }

            let predicateBody = NSPredicate.init(format: "bodyFetched = true")
            let predicateDecrypted = NSPredicate.init(format: "pepColorRating != nil")
            let predicates: [NSPredicate] = [predicateBody, predicateDecrypted]
            let predicate = NSCompoundPredicate.init(
                andPredicateWithSubpredicates: predicates)
            let sortDescriptors = [NSSortDescriptor.init(key: "receivedDate",
                ascending: false)]

            emailListConfig = EmailListConfig.init(
                appConfig: ac, predicate: predicate,
                sortDescriptors: sortDescriptors, account: accounts[indexPath.row])

            self.performSegueWithIdentifier(segueEmailList, sender: self)
        } else {
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueEmailList {
            guard let vc = segue.destinationViewController as?
                EmailListViewController else {
                return
            }
            vc.config = emailListConfig
        }
    }
}