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
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var passwordValue: UITextField!

    var mailParameters = MailSettingParameters()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem!.enabled = false
    }

    @IBAction func editingEmail(sender: UITextField) {
        print(emailValue.text)
        if (emailValue.text != "" && passwordValue.text != "") {
             self.navigationItem.rightBarButtonItem!.enabled = true
        }
        else {
            self.navigationItem.rightBarButtonItem!.enabled = false
        }
    }
    @IBAction func editingPassword(sender: UITextField) {
        if (emailValue.text != "" && passwordValue.text != "")  {
            self.navigationItem.rightBarButtonItem!.enabled = true
        }
        else {
            self.navigationItem.rightBarButtonItem!.enabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IMAPSettings" {
            mailParameters.email = emailValue.text!
            mailParameters.username = usernameValue.text!
            mailParameters.password = passwordValue.text!
            if let destination = segue.destinationViewController as? IMAPSettingsTableView {
               destination.mailParameters = mailParameters
            }
        }
    }
}

  

