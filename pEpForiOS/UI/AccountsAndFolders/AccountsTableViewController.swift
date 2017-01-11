//
//  AccountsFoldersViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AccountsTableViewController: UITableViewController {
    let comp = "AccountsTableViewController"

    /** Our vanilla table view cell */
    let accountsCellIdentifier = "accountsCell"

    /** Two sections, one for the folders, one for the accounts */
    let numberOfSections = 1

    /** The index of the section where important folders are listed */
    let folderSection = 0

    var appConfig: AppConfig!
    var accounts = [Account]()

    /** For email list configuration */
    var emailListConfig: EmailListConfig?

    /** For starting mySelf() */
    var backgroundQueue = OperationQueue.init()

    struct UIState {
        var isSynching = false
    }

    var state = UIState.init()
    var selectedAccount: Account? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if MiscUtil.isUnitTest() {
            super.viewWillAppear(animated)
            return
        }

        if appConfig == nil {
            guard let appDelegate = UIApplication.shared.delegate as?
                AppDelegate
            else {
                    return
            }
            appConfig = appDelegate.appConfig
        }
        updateModel()
    }

    func updateModel() {
        accounts = Account.all()
        tableView.reloadData()
    }

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
    }

    @IBAction func newAccountCreatedSegue(_ segue: UIStoryboardSegue) {
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return accounts.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Accounts.HeaderTitle".localized
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
        cell.textLabel?.text = accounts[indexPath.row].user.address
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAccount = accounts[indexPath.row]
        performSegue(withIdentifier: .segueEditAccount, sender: self)
    }
    
    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Navigation

extension AccountsTableViewController: SegueHandlerType {
    
    enum SegueIdentifier: String {
        case segueAddNewAccount
        case segueEditAccount
        case noSegue
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueEditAccount:
            guard
                let destination = segue.destination as? AccountSettingsTableViewController
            else {
                return
            }
            destination.account = selectedAccount
            break
        default:()
        }
        
    }
    
}
