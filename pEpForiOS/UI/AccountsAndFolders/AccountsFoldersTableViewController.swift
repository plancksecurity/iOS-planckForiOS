//
//  AccountsFoldersViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountsFoldersViewController: UITableViewController {
    let comp = "AccountsFoldersViewController"

    /** Segue to the new account setup */
    let segueSetupNewAccount = "segueSetupNewAccount"

    /** The segue to the `EmailListViewController` */
    let segueEmailList = "segueEmailList"

    /** The segue to the folder list */
    let segueFolderList = "segueFolderList"

    /** Our vanilla table view cell */
    let standardCell = "standardCell"

    /** Two sections, one for the folders, one for the accounts */
    let numberOfSections = 2

    /** The index of the section where important folders are listed */
    let folderSection = 0

    var appConfig: AppConfig!
    var accounts = [IAccount]()

    /** For email list configuration */
    var emailListConfig: EmailListViewController.EmailListConfig?

    /** For folder list configuration */
    var folderListConfig: FolderListViewController.FolderListConfig?

    /** For starting mySelf() */
    var backgroundQueue = NSOperationQueue.init()

    struct UIState {
        var isSynching = false
    }

    var state = UIState.init()

    var shouldRefreshMail = true

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: standardCell)

        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refreshMailsControl),
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

        updateModel()

        if accounts.isEmpty {
            self.performSegueWithIdentifier(segueSetupNewAccount, sender: self)
        } else {
            doMyself()
        }

        if shouldRefreshMail {
            refreshMailsControl()
            shouldRefreshMail = false
        }

        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateModel() {
        guard let model = appConfig?.model else {
            return
        }
        if let allAccounts = model.accountsByPredicate(
            NSPredicate.init(value: true),
            sortDescriptors: [NSSortDescriptor.init(key: "email", ascending: true)]) {
            accounts = allAccounts
        }
        tableView.reloadData()
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

    func refreshMailsControl(refreshControl: UIRefreshControl? = nil) {
        guard let ac = appConfig else {
            return
        }

        if state.isSynching {
            return
        }

        let connectInfos = accounts.map({return $0.connectInfo})

        state.isSynching = true
        updateUI()

        ac.grandOperator.fetchEmailsAndDecryptConnectInfos(
            connectInfos, folderName: nil,
            completionBlock: { error in
                Log.infoComponent(self.comp, "Sync completed, error: \(error)")
                if let err = error {
                    UIHelper.displayError(err, controller: self)
                }
                ac.model.save()
                self.state.isSynching = false
                self.updateUI()
        })
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

    @IBAction func newAccountCreatedSegue(segue: UIStoryboardSegue) {
        // load new account
        updateModel()

        doMyself()

        refreshMailsControl()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(
        tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == folderSection {
            // Number of important folders to display, which at the moment
            // is equal to the number of                                                                                                       (number of inboxes)
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

    /**
     Basic predicate for listing all emails from any INBOX.
     */
    func basicInboxPredicate() -> NSPredicate {
        let predicateBasic = appConfig.model.basicMessagePredicate()
        let predicateInbox = NSPredicate.init(
            format: "folder.folderType = %d", FolderType.Inbox.rawValue)
        let predicates: [NSPredicate] = [predicateBasic, predicateInbox]
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        return predicate
    }

    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == folderSection {
            guard let ac = appConfig else {
                return
            }
            let account = accounts[indexPath.row]

            let predicateInbox = basicInboxPredicate()
            let predicateAccount = NSPredicate.init(
                format: "folder.account.email = %@", account.email)
            let predicates: [NSPredicate] = [predicateInbox, predicateAccount]
            let predicate = NSCompoundPredicate.init(
                andPredicateWithSubpredicates: predicates)
            let sortDescriptors = [NSSortDescriptor.init(key: "receivedDate",
                ascending: false)]

            emailListConfig = EmailListViewController.EmailListConfig.init(
                appConfig: ac, predicate: predicate,
                sortDescriptors: sortDescriptors, account: account,
                folderName: ImapSync.defaultImapInboxName)

            self.performSegueWithIdentifier(segueEmailList, sender: self)
        } else {
            folderListConfig = FolderListViewController.FolderListConfig.init(
                account: accounts[indexPath.row], appConfig: appConfig)
            self.performSegueWithIdentifier(segueFolderList, sender: self)
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
        } else if segue.identifier == segueFolderList {
            guard let vc = segue.destinationViewController as?
                FolderListViewController else {
                    return
            }
            vc.config = folderListConfig
        }
    }
}