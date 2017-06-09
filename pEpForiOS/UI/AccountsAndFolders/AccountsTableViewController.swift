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

    let viewModel = AccountsSettingsViewModel()

    /** Our vanilla table view cell */
    let accountsCellIdentifier = "accountsCell"

    var appConfig: AppConfig!

    /** For email list configuration */
    //var emailListConfig: EmailListConfig?

    struct UIState {
        var isSynching = false
    }

    var state = UIState.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Accounts", comment: "Accounts view title")
        UIHelper.variableCellHeightsTableView(self.tableView)
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
        //reload data in view model
        tableView.reloadData()
    }

    func updateUI() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = state.isSynching
    }

    @IBAction func newAccountCreatedSegue(_ segue: UIStoryboardSegue) {
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  viewModel[section].count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
        cell.textLabel?.text = viewModel[indexPath.section][indexPath.item].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.section == 1 {
            if indexPath.row == 1 {

            } else {
                performSegue(withIdentifier: .segueShowLog, sender: self)
            }
        } else {
            //selectedAccount = accounts[indexPath.row]
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
            //destination.account = selectedAccount
            break
        default:()
        }
        
    }
    
}
