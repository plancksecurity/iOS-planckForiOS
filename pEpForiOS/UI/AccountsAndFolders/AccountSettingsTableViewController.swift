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
        return 3
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

        var imap: (address: String?, port: String?, transport: String?)
        imap.address = imapServerTextfield.text
        imap.port = imapPortTextfield.text
        imap.transport = imapSecurityTextfield.text

        var smtp: (address: String?, port: String?, transport: String?)
        smtp.address = smtpServerTextfield.text
        smtp.port = smtpPortTextfield.text
        smtp.transport = smtpSecurityTextfield.text

        if let name = nameTextfield.text, name != "", let loginName = usernameTextfield.text, loginName != "" {
            viewModel?.update(loginName: loginName, name: name, password: passwordTextfield.text)
            navigationController?.popViewController(animated: true)
        }
        
    }
}
