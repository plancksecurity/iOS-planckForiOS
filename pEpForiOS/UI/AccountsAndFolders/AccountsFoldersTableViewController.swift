//
//  AccountsFoldersViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

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
    var accounts = [Account]()

    /** For email list configuration */
    var emailListConfig: EmailListConfig?

    /** For folder list configuration */
    var folderListConfig: FolderListViewController.FolderListConfig?

    /** For starting mySelf() */
    var backgroundQueue = OperationQueue.init()

    struct UIState {
        var isSynching = false
    }

    var state = UIState.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: standardCell)
    }

    override func viewWillAppear(_ animated: Bool) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            super.viewWillAppear(animated)
            return
        }

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

        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateModel() {
        accounts = Account.all()
        tableView.reloadData()
    }

    func doMyself() {
        let accounts = Account.all()
        for acc in accounts {
            let op = PEPMyselfOperation(account: acc)
            backgroundQueue.addOperation(op)
        }
    }

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
    }

    @IBAction func newAccountCreatedSegue(_ segue: UIStoryboardSegue) {
        // load new account
        updateModel()

        doMyself()
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

            let email = accounts[(indexPath as NSIndexPath).row].user.address
            cell.textLabel?.text = String.init(
                format: NSLocalizedString(
                    "Inbox (%@)", comment: "Table view label for an inbox for an account"), email)
            cell.accessoryType = .disclosureIndicator

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: standardCell, for: indexPath)

            cell.textLabel?.text = accounts[(indexPath as NSIndexPath).row].user.address
            cell.accessoryType = .disclosureIndicator

            return cell
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == folderSection {
            guard let ac = appConfig else {
                return
            }
            let account = accounts[(indexPath as NSIndexPath).row]
            let inbox = account.inbox()

            emailListConfig = EmailListConfig.init(
                appConfig: ac, account: account, folder: inbox)

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
    
    // MARK: - Actions
    
    @IBAction func addAccountButtonTapped(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: segueSetupNewAccount, sender: self)
    }
    
    @IBAction func unwindToAccounts(for unwindSegue: UIStoryboardSegue) {
        
    }
}
