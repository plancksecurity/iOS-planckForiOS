//
//  AccountSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 12/22/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class AccountSettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!

    @IBOutlet weak var imapServerTextfield: UITextField!
    @IBOutlet weak var imapPortTextfield: UITextField!
    @IBOutlet weak var imapSecurityTextfield: UITextField!
    
    @IBOutlet weak var smtpServerTextfield: UITextField!
    @IBOutlet weak var smtpPortTextfield: UITextField!
    @IBOutlet weak var smtpSecurityTextfield: UITextField!
    
    var account: Account? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populeteAccount()
        populateIMAP()
        populateSMTP()
    }
    
    func populeteAccount() {
        nameTextfield.text = account?.user.displayString
        emailTextfield.text = account?.user.address
        usernameTextfield.text = account?.user.userName
    }
    
    func  populateIMAP() {
        if let serverCredentials = account?.serverCredentials[safe: 0],
            let server = serverCredentials.servers[safe: 0] {
            imapServerTextfield.text = server.address
            imapPortTextfield.text = "\(server.port)"
        }
        
    }
    
    func populateSMTP() {
        if let serverCredentials = account?.serverCredentials[safe: 0],
            let server = serverCredentials.servers[safe: 0] {
            smtpServerTextfield.text = server.address
            smtpPortTextfield.text = "\(server.port)"
        }
    }
    
    // MARK: - UItableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        if (account?.hasBeenPopulated)! {
            return 1
        }
        return 3
    }
    
    override func tableView(
        _ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Account", comment: "Account settings")
        case 1:
            return NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP")
        case 2:
            return NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")
        default:
            return""
        }
    }
    
    override func tableView(
        _ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
      let _ =  navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
    }
}
