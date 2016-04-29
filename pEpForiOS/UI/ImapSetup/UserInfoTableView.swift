//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

public struct ModelUserInfoTable {
    public var emailTextExist:Bool = false
    public var passwordTextExist:Bool = false

    public init(emailTextExist:Bool,passwordTextExist:Bool) {
        self.emailTextExist = emailTextExist
        self.passwordTextExist = passwordTextExist
    }

    public func shouldEnableNextButton()-> Bool {
        return emailTextExist &&  passwordTextExist
    }
}

public class UserInfoTableView: UITableViewController {


    @IBOutlet weak var emailValue: UITextField!
    @IBOutlet weak var passwordValue: UITextField!
    @IBOutlet weak var usernameValue: UITextField!

    var mailParameters = MailSettingParameters()
    public var model = ModelUserInfoTable(emailTextExist: false,passwordTextExist: false)

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem!.enabled = false
    }

    @IBAction func editingEmail(sender: UITextField) {
        model.emailTextExist = emailValue.text != ""
        updateView()
    }
    @IBAction func editingPassword(sender: UITextField) {
        model.passwordTextExist = passwordValue.text != ""
        updateView()
    }

    func updateView() {
        self.navigationItem.rightBarButtonItem!.enabled = model.shouldEnableNextButton()
    }
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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

  

