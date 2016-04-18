//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit


class UserInfoTableView: UITableViewController {

   
    @IBOutlet weak var emailValue: UITextField!
    @IBOutlet weak var UsernameValue: UITextField!
    @IBOutlet weak var PasswordValue: UITextField!

    var mailParameters = MailSettingParameters(email: " ", username: " ", password: " ", serverhostIMAP: " ", portIMAP: " ", transportSecurityIMAP: " ", serverhostSMTP: " ", portSMTP: " ", transportSecuritySMTP: " ")

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IMAPSettings" {
            mailParameters.email = emailValue.text!
            mailParameters.username = UsernameValue.text!
            mailParameters.password = PasswordValue.text!
            if let destination = segue.destinationViewController as? IMAPSettingsTableView {
               destination.mailParameters = mailParameters
            }
        }
    }
}

  

