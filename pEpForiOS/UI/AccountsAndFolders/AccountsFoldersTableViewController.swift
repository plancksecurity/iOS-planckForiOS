//
//  AccountsFoldersViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

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
    var accounts = [CdAccount]()

    /** For email list configuration */
    var emailListConfig: EmailListViewController.EmailListConfig?

    /** For folder list configuration */
    var folderListConfig: FolderListViewController.FolderListConfig?

    /** For starting mySelf() */
    var backgroundQueue = OperationQueue.init()

    struct UIState {
        var isSynching = false
    }

    var state = UIState.init()

    var shouldRefreshMail = true

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: standardCell)

        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refreshMailsControl),
                                    for: UIControlEvents.valueChanged)
        self.refreshControl = refreshController
    }

    override func viewWillAppear(_ animated: Bool) {
        if appConfig == nil {
            guard let appDelegate = UIApplication.shared.delegate as?
                AppDelegate else {
                    super.viewWillAppear(animated)
                    return
            }
            appConfig = appDelegate.appConfig
        }

        updateModel()

        if accounts.isEmpty {
            self.performSegue(withIdentifier: segueSetupNewAccount, sender: self)
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

    func refreshMailsControl(_ refreshControl: UIRefreshControl? = nil) {
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
                UIHelper.displayError(error, controller: self)
                ac.model.save()
                self.state.isSynching = false
                self.updateUI()
        })
    }

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
        if !state.isSynching {
            self.refreshControl?.endRefreshing()
        }
    }

    @IBAction func newAccountCreatedSegue(_ segue: UIStoryboardSegue) {
        // load new account
        updateModel()

        doMyself()

        refreshMailsControl()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if accounts.isEmpty {
            return 0
        } else {
        return numberOfSections
        }
    }

    override func tableView(
        _ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == folderSection {
            // Number of important folders to display, which at the moment
            // is equal to the number of inboxes)
            return accounts.count
        } else {
            return accounts.count
        }
    }

    override func tableView(
        _ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == folderSection {
            return NSLocalizedString(
                "Folders", comment: "Section title for important folder list")
        } else {
            return NSLocalizedString(
                "Accounts", comment: "Section title for account list")
        }
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == folderSection {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: standardCell, for: indexPath)

            let email = accounts[(indexPath as NSIndexPath).row].email
            cell.textLabel?.text = String.init(
                format: NSLocalizedString(
                    "Inbox (%@)", comment: "Table view label for an inbox for an account"), email)
            cell.accessoryType = .disclosureIndicator

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: standardCell, for: indexPath)

            cell.textLabel?.text = accounts[(indexPath as NSIndexPath).row].email
            cell.accessoryType = .disclosureIndicator

            return cell
        }
    }

    // MARK: - Table view delegate

    /**
     Basic predicate for listing all emails from any INBOX.
     */
    func basicInboxPredicate() -> NSPredicate {
        let predicateBasic = appConfig.model.basicMessagePredicate()
        let predicateInbox = NSPredicate.init(
            format: "folder.folderType = %d", FolderType.inbox.rawValue)
        let predicates: [NSPredicate] = [predicateBasic, predicateInbox]
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        return predicate
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == folderSection {
            guard let ac = appConfig else {
                return
            }
            let account = accounts[(indexPath as NSIndexPath).row]

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
                folderName: ImapSync.defaultImapInboxName,
                syncOnAppear: false)

            self.performSegue(withIdentifier: segueEmailList, sender: self)
        } else {
            folderListConfig = FolderListViewController.FolderListConfig.init(
                account: accounts[(indexPath as NSIndexPath).row], appConfig: appConfig)
            self.performSegue(withIdentifier: segueFolderList, sender: self)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueEmailList {
            guard let vc = segue.destination as?
                EmailListViewController else {
                return
            }
            vc.config = emailListConfig
        } else if segue.identifier == segueFolderList {
            guard let vc = segue.destination as?
                FolderListViewController else {
                    return
            }
            vc.config = folderListConfig
        }
    }
}
