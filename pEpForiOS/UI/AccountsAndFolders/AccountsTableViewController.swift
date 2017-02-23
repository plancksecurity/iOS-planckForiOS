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
    let numberOfSections = 2

    /** The index of the section where important folders are listed */
    let folderSection = 0

    var appConfig: AppConfig!
    var accounts = [Account]()

    /** For email list configuration */
    var emailListConfig: EmailListConfig?

    struct UIState {
        var isSynching = false
    }

    var state = UIState.init()
    var selectedAccount: Account? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       title = "Accounts.title".localized
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
        switch section {
        case 0:
            return accounts.count
        case 1:
            return 1
        default:
            return 0
        }
            //return accounts.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Accounts.title".localized
        case 1:
            return "Settings".localized
        default:
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {

            let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
            cell.textLabel?.text = accounts[indexPath.row].user.address
            cell.accessoryType = .disclosureIndicator
            return cell

        } else if indexPath.section == 1 {

            let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
            cell.textLabel?.text = "Logging".localized
            cell.accessoryType = .disclosureIndicator
            return cell

        }

        let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
        cell.textLabel?.text = accounts[indexPath.row].user.address
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.section == 1 {
            performSegue(withIdentifier: .segueShowLog, sender: self)
        } else {
            selectedAccount = accounts[indexPath.row]
            performSegue(withIdentifier: .segueEditAccount, sender: self)
        }


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
        case segueShowLog
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
