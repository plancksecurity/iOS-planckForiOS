//
//  LoginTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/05/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

enum LoginTableViewControllerError: Error {
    case missingEmail
    case missingPassword
    case missingUserName
    case noConnectData
}

extension LoginTableViewControllerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingEmail:
            return NSLocalizedString("Email needed",
                                     comment: "Automated account setup error description")
        case .missingPassword:
            return NSLocalizedString("Password needed",
                                     comment: "Automated account setup error description")
        case .missingUserName:
            return NSLocalizedString("User name needed",
                                     comment: "Automated account setup error description")
        case .noConnectData:
            return NSLocalizedString("Internal error",
                                     comment: "Automated account setup error description")
        }
    }
}

class LoginTableViewController: UITableViewController, UITextFieldDelegate {
    var appConfig: AppConfig? {
        didSet {
            loginViewModel.messageSyncService = appConfig?.messageSyncService
        }
    }

    var loginViewModel = LoginViewModel()
    var extendedLogin = false

    @IBOutlet var username: UITextField!
    @IBOutlet var emailAddress: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var manualConfigButton: UIButton!
    @IBOutlet var loginButton: UIButton!

    @IBOutlet var usernameTableViewCell: UITableViewCell!
    @IBOutlet var emailTableViewCell: UITableViewCell!
    @IBOutlet var passwordTableViewCell: UITableViewCell!
    @IBOutlet var loginTableViewCell: UITableViewCell!
    @IBOutlet var manualConfigTableViewCell: UITableViewCell!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!


    let status = ViewStatus()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }

    func configureView(){
        UIHelper.variableCellHeightsTableView(self.tableView)
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
        self.tableView.contentInset = UIEdgeInsets(top: 30,left: 0,bottom: 0,right: 0)
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

    func updateView() {
        if status.activityIndicatorViewEnable {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        navigationItem.rightBarButtonItem?.isEnabled = !(status.activityIndicatorViewEnable)
        loginButton.isEnabled = !(status.activityIndicatorViewEnable)
        manualConfigButton.isEnabled = !(status.activityIndicatorViewEnable)
    }

    @IBAction func logIn(_ sender: Any) {
        self.status.activityIndicatorViewEnable = true
        updateView()
        guard let email = emailAddress.text, email != "" else {
            handleLoginError(error: LoginTableViewControllerError.missingEmail)
            return
        }
        guard let pass = password.text, pass != "" else {
            handleLoginError(error: LoginTableViewControllerError.missingPassword)
            return
        }

        loginViewModel.delegate = self
        if extendedLogin {
            guard let username = username.text else {
                handleLoginError(
                    error: LoginTableViewControllerError.missingUserName)
                return
            }
                loginViewModel.login(
                account: email, password: pass, username: username) { (err) in
                    if let error = err {
                        handleLoginError(error: error)
                    }
                }
        } else {
            loginViewModel.login(account: email, password: pass) { (err) in
                if let error = err {
                    handleLoginError(error: error)
                }
            }
        }
    }

    public func handleLoginError(error: Error) {
        Log.shared.error(component: #function, error: error)
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
                self.status.activityIndicatorViewEnable = false
                self.updateView()
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
        case BackToEmailList
    }
}

extension LoginTableViewController: accountVerificationResultDelegate {
    func Result(result: AccountVerificationResult) {
        GCD.onMain() {
            switch result {
            case .ok:
                // unwind back to INBOX on success
                self.performSegue(withIdentifier: .BackToEmailList, sender: self)
            case .imapError(let err):
                self.handleLoginError(error: err)
            case .smtpError(let err):
                self.handleLoginError(error: err)
            case .noImapConnectData, .noSmtpConnectData:
                self.handleLoginError(error: LoginTableViewControllerError.noConnectData)
            }
        }
    }
}
