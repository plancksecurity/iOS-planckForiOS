//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

public class ModelUserInfoTable {

    public var email: String?

    /**
     The actual name of the user, or nick name.
     */
    public var name: String?

    /**
     An optional name for the servers, if needed.
     */
    public var username: String?
    public var password: String?
    public var serverIMAP: String?
    public var portIMAP: UInt16 = 993
    public var transportIMAP = ConnectionTransport.TLS
    public var serverSMTP: String?
    public var portSMTP: UInt16 = 587
    public var transportSMTP = ConnectionTransport.StartTLS

    public var isValidEmail: Bool {
        return email != nil && email!.isProbablyValidEmail()
    }

    public var isValidPassword: Bool {
        return password != nil && password!.characters.count > 0
    }

    public var isValidName: Bool {
        return name?.characters.count >= 3
    }

    public var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    public var isValidImap: Bool {
        return false
    }

    public var isValidSmtp: Bool {
        return false
    }
}

public class UserInfoTableView: UITableViewController, UITextFieldDelegate {
    let comp = "UserInfoTableView"

    @IBOutlet weak var emailValue: UITextField!
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var passwordValue: UITextField!

    @IBOutlet weak var emailTitleTextField: UILabel!
    @IBOutlet weak var usernameTitleTextField: UILabel!
    @IBOutlet weak var passwordTitleTextField: UILabel!
    @IBOutlet weak var nameOfTheUserValueTextField: UITextField!
    @IBOutlet weak var nameOfTheUserTitleTextField: UILabel!

    var appConfig: AppConfig?
    var IMAPSettings = "IMAPSettings"

    public var model = ModelUserInfoTable()

    let viewWidthAligner = ViewWidthsAligner()

    public override func viewDidLoad() {
        super.viewDidLoad()
        passwordValue.delegate = self
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewWidthAligner.alignViews([emailTitleTextField,
            usernameTitleTextField, passwordTitleTextField, nameOfTheUserTitleTextField], parentView: self.view)
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }

        guard let ac = appConfig else {
            Log.errorComponent(comp, errorString: "Have no app config")
            return
        }

        // TODO: This is not enough!
        self.navigationItem.hidesBackButton = ac.model.accountsIsEmpty()

        if model.email == nil {
            nameOfTheUserValueTextField.becomeFirstResponder()
        }

        updateView()
    }

    func updateView() {
        self.navigationItem.rightBarButtonItem?.enabled = model.isValidUser
        // TODO: update the complete view (email etc.)
    }

    /**
     Sometimes you have to put stuff from the view into the model again.
     */
    func updateModel() {}

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IMAPSettings" {
            let destination = segue.destinationViewController as! IMAPSettingsTableView
            destination.appConfig = appConfig
            destination.model = model
        }
    }

    public func textFieldShouldReturn(passwordValue: UITextField) -> Bool {
        if (model.isValidUser) {
            self.performSegueWithIdentifier(self.IMAPSettings, sender: passwordValue)
        }
        return true;
    }

    @IBAction func changeEmail(sender: UITextField) {
        model.email = sender.text
        updateView()
    }

    @IBAction func changeUsername(sender: UITextField) {
        model.username = sender.text
        updateView()
    }

    @IBAction func changePassword(sender: UITextField) {
        model.password = sender.text
        updateView()
    }

    @IBAction func changedName(sender: UITextField) {
        model.name = sender.text
        updateView()
    }
}