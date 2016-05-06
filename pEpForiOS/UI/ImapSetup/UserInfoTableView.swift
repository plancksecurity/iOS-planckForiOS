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

    var appConfig: AppConfig?
    var mailSettings = MailSettingParameters()

    public var model = ModelUserInfoTable(emailTextExist: false,passwordTextExist: false)

    override public func viewDidLoad() {
        super.viewDidLoad()
        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem!.enabled = false
    }

    func updateView() {
        self.navigationItem.rightBarButtonItem!.enabled = model.shouldEnableNextButton()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        mailSettings.email = emailValue.text!
        mailSettings.username = usernameValue.text!
        mailSettings.password = passwordValue.text!
        if segue.identifier == "IMAPSettings" {
            if let destination = segue.destinationViewController as? IMAPSettingsTableView {
                destination.appConfig = appConfig
                destination.mailSettings = mailSettings
            }
        }
    }

    @IBAction func textFieldDoneEditing(sender: AnyObject) {
        sender.resignFirstResponder()
    }
    @
    IBAction func editingEmail(sender: UITextField) {
        model.emailTextExist = emailValue.text != ""
        updateView()
    }

    @IBAction func editingPassword(sender: UITextField) {
        model.passwordTextExist = passwordValue.text != ""
        updateView()
    }
}

  

