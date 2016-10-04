//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


open class ModelUserInfoTable {

    open var email: String?

    /**
     The actual name of the user, or nick name.
     */
    open var name: String?

    /**
     An optional name for the servers, if needed.
     */
    open var username: String?
    open var password: String?
    open var serverIMAP: String?
    open var portIMAP: UInt16 = 993
    open var transportIMAP = ConnectionTransport.TLS
    open var serverSMTP: String?
    open var portSMTP: UInt16 = 587
    open var transportSMTP = ConnectionTransport.startTLS

    open var isValidEmail: Bool {
        return email != nil && email!.isProbablyValidEmail()
    }

    open var isValidPassword: Bool {
        return password != nil && password!.characters.count > 0
    }

    open var isValidName: Bool {
        return name?.characters.count >= 3
    }

    open var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    open var isValidImap: Bool {
        return false
    }

    open var isValidSmtp: Bool {
        return false
    }
}

open class UserInfoTableView: UITableViewController, UITextFieldDelegate {
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

    open var model = ModelUserInfoTable()

    let viewWidthAligner = ViewWidthsAligner()

    open override func viewDidLoad() {
        super.viewDidLoad()
        passwordValue.delegate = self
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewWidthAligner.alignViews([emailTitleTextField,
            usernameTitleTextField, passwordTitleTextField, nameOfTheUserTitleTextField], parentView: self.view)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if appConfig == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
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
        self.navigationItem.rightBarButtonItem?.isEnabled = model.isValidUser
        // TODO: update the complete view (email etc.)
    }

    /**
     Sometimes you have to put stuff from the view into the model again.
     */
    func updateModel() {}

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "IMAPSettings" {
            let destination = segue.destination as! IMAPSettingsTableView
            destination.appConfig = appConfig
            destination.model = model
        }
    }

    open func textFieldShouldReturn(_ passwordValue: UITextField) -> Bool {
        if (model.isValidUser) {
            self.performSegue(withIdentifier: self.IMAPSettings, sender: passwordValue)
        }
        return true;
    }

    @IBAction func changeEmail(_ sender: UITextField) {
        model.email = sender.text
        updateView()
    }

    @IBAction func changeUsername(_ sender: UITextField) {
        model.username = sender.text
        updateView()
    }

    @IBAction func changePassword(_ sender: UITextField) {
        model.password = sender.text
        updateView()
    }

    @IBAction func changedName(_ sender: UITextField) {
        model.name = sender.text
        updateView()
    }
}
