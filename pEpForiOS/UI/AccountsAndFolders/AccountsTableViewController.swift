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

    var ipath : IndexPath?
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

        if indexPath.section == 1 && indexPath.row == 1 {

            let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
            cell.textLabel?.text = viewModel[indexPath.section][indexPath.item].title
            let switchView = UISwitch(frame: CGRect.zero)
            switchView.setOn(false, animated: false)
            switchView.addTarget(self, action: #selector(switchChanged(sender:)), for: UIControlEvents.valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: accountsCellIdentifier, for: indexPath)
        cell.textLabel?.text = viewModel[indexPath.section][indexPath.item].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")

            viewModel.delete(section: indexPath.section, cell: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func switchChanged(sender: UISwitch) {
        NSLog( "The switch is %@", sender.isOn ? "ON" : "OFF" );
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
            self.ipath = indexPath
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
            if let path = ipath {
                if let acc = viewModel[path.section][path.row].account {
                    var vm = AccountSettingsViewModel(account: acc)
                    destination.viewModel = vm
                }
            }
            break
        default:()
        }
        
    }
    
}
