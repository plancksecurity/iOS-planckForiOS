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
        let serverCredentials = (account?.serverCredentials[safe: 0])! as ServerCredentials
        let server = serverCredentials.servers[safe: 0]! as Server
        imapServerTextfield.text = server.address
        imapPortTextfield.text = "\(server.port)"
        
    }
    
    func populateSMTP() {
        let serverCredentials = (account?.serverCredentials[safe: 0])! as ServerCredentials
        let server = serverCredentials.servers[safe: 0]! as Server
        smtpServerTextfield.text = server.address
        smtpPortTextfield.text = "\(server.port)"
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "AccountsSettings.Account".localized
        case 1:
            return "AccountsSettings.IMAP".localized
        case 2:
            return "AccountsSettings.SMPT".localized
        default:
            return""
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
