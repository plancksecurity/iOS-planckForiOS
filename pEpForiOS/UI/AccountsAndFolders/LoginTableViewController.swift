//
//  LoginTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/05/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class LoginTableViewController: UITableViewController, UITextFieldDelegate {
    let loginViewModel = LoginViewModel()
    var extendedLogin = false

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var manualConfigButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var usernameTableViewCell: UITableViewCell!
    @IBOutlet weak var emailTableViewCell: UITableViewCell!
    @IBOutlet weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet weak var loginTableViewCell: UITableViewCell!
    @IBOutlet weak var manualConfigTableViewCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        MessageModelConfig.accountDelegate = self
    }

    func configureView(){
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        self.view.applyGradient(colours: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        self.emailAddress.delegate = self
        self.password.delegate = self
        self.username.delegate = self
        self.emailAddress.convertToLoginTextField(
            placeHolder: NSLocalizedString("Email", comment: "Email"))
        self.password.convertToLoginTextField(
            placeHolder: NSLocalizedString("Password", comment: "password"))
        self.loginButton.convertToLoginButton(
            placeHolder: NSLocalizedString("Sign In", comment: "Login"))
        self.username.convertToLoginTextField(
            placeHolder: NSLocalizedString("Username", comment: "username"))
        self.manualConfigButton.convertToLoginButton(
            placeHolder: NSLocalizedString("Manual configuration", comment: "manual"))
        self.navigationController?.navigationBar.isHidden = !loginViewModel.isThereAnAccount()
        self.view.applyGradient(colours: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        self.tableView.contentInset = UIEdgeInsets(top: 30,left: 0,bottom: 0,right: 0)
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor  = UIColor.pEpGreen
        usernameTableViewCell.backgroundColor = UIColor.clear
        emailTableViewCell.backgroundColor = UIColor.clear
        passwordTableViewCell.backgroundColor = UIColor.clear
        loginTableViewCell.backgroundColor = UIColor.clear
        manualConfigTableViewCell.backgroundColor = UIColor.clear
        manualConfigButton.isHidden = true
        username.isHidden = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginTableViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func logIn(_ sender: Any) {
        if let email = emailAddress.text, email != "", let pass = password.text, pass != "" {
            if extendedLogin {
                if let username = username.text, username != "" {
                    loginViewModel.login(
                    account: email, password: pass, username: username) { (err) in
                        if let error = err {
                            handleLoginError(error: error, autoSegue: true)
                        }
                    }
                } else {
                    handleLoginError(error: Constants.errorInvalidParameter("login Screen"),
                                     autoSegue: false)
                }
            } else {
                loginViewModel.login(account: email, password: pass) { (err) in
                    if let error = err {
                        handleLoginError(error: error, autoSegue: true)
                    }
                }
            }
        } else {
            handleLoginError(error: Constants.errorInvalidParameter("login Screen"),
                             autoSegue: false)
        }
    }

    public func handleLoginError(error: Error, autoSegue: Bool) {
        let alertView = UIAlertController(
            title: NSLocalizedString(
                "Error",
                comment: "UIAlertController error title"),
            message:error.localizedDescription, preferredStyle: .alert)
        alertView.view.tintColor = .pEpGreen
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "View log",
                comment: "Button for viewing the log on error"),
            style: .default, handler: { action in
                self.viewLog()
        }))
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "Ok",
                comment: "UIAlertAction ok after error"),
            style: .default, handler: {action in
                if autoSegue {

                }
                self.username.isHidden = false
                self.manualConfigButton.isHidden = false
                self.extendedLogin = true
        }))
        present(alertView, animated: true, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.username {
            self.emailAddress.becomeFirstResponder()
        } else if textField == self.emailAddress {
            self.password.becomeFirstResponder()
        } else if textField == self.password {
            dismissKeyboard()
            self.logIn(self.password)
        }
        return true
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func viewLog() {
        performSegue(withIdentifier: .viewLogSegue, sender: self)
    }
}

extension LoginTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case noSegue
        case viewLogSegue
    }
}

extension LoginTableViewController: AccountDelegate {

    public func didVerify(account: Account, error: Error?) {
        GCD.onMain() {
            if let err = error {
                self.handleLoginError(error: err as NSError, autoSegue: false)
            } else {
                // unwind back to INBOX on success
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
