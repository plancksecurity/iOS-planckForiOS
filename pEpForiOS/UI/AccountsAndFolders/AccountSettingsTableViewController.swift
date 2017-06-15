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

    var viewModel: AccountSettingsViewModel? = nil
    
     override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    func configureView() {
        self.nameTextfield.text = viewModel?.name
        self.emailTextfield.text = viewModel?.email
        self.usernameTextfield.text = viewModel?.loginName

        let imap = viewModel?.imapServer
        self.imapServerTextfield.text = imap?.address
        self.imapPortTextfield.text = imap?.port
        self.imapSecurityTextfield.text = imap?.transport

        let smtp = viewModel?.smtpServer
        self.smtpServerTextfield.text = smtp?.address
        self.smtpPortTextfield.text = smtp?.port
        self.smtpSecurityTextfield.text = smtp?.transport
    }
    // MARK: - UItableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let vm = viewModel {
            if vm.accountHasBeenPopulated {
                return 1
            }
            return 3
        }
        return 0
    }
    
    override func tableView(
        _ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel?[section]
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
