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

    @IBOutlet var loginName: UITextField!
    @IBOutlet var emailAddress: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var manualConfigButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var user: UITextField!

    @IBOutlet var loginNameTableViewCell: UITableViewCell!
    @IBOutlet var UserTableViewCell: UITableViewCell!
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
        if appConfig == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }

        updateView()
    }

    func configureView(){
        UIHelper.variableCellHeightsTableView(self.tableView)
        self.emailAddress.convertToLoginTextField(
            placeHolder: NSLocalizedString("Email", comment: "Email"), delegate: self)
        self.password.convertToLoginTextField(
            placeHolder: NSLocalizedString("Password", comment: "password"), delegate: self)
        self.loginButton.convertToLoginButton(
            placeHolder: NSLocalizedString("Sign In", comment: "Login"))
        self.loginName.convertToLoginTextField(
            placeHolder: NSLocalizedString("Log In Name", comment: "LoginName"), delegate: self)
        self.manualConfigButton.convertToLoginButton(
            placeHolder: NSLocalizedString("Manual configuration", comment: "manual"))
        self.user.convertToLoginTextField(
            placeHolder: NSLocalizedString("Name", comment: "username"), delegate: self)

        self.navigationController?.navigationBar.isHidden = !loginViewModel.isThereAnAccount()
        //color and spacing configurations
        self.view.applyGradient(colours: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        self.tableView.contentInset = UIEdgeInsets(top: 30,left: 0,bottom: 0,right: 0)
        self.tableView.backgroundColor  = UIColor.pEpGreen
        //clear cell color
        UserTableViewCell.backgroundColor = UIColor.clear
        emailTableViewCell.backgroundColor = UIColor.clear
        passwordTableViewCell.backgroundColor = UIColor.clear
        loginTableViewCell.backgroundColor = UIColor.clear
        manualConfigTableViewCell.backgroundColor = UIColor.clear
        loginNameTableViewCell.backgroundColor = UIColor.clear
        //hide extended login fields
        manualConfigButton.isHidden = true
        loginName.isHidden = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginTableViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title:"Cancel", style:.plain, target:self, action:#selector(self.backButton))
        //self.navigationController?.navigationBar.backItem = UIBarButtonItem(title:"Cancel", style:.plain, target:self, action:#selector(self.backButton))
    }

    func backButton() {
        self.navigationController?.popViewController(animated: true)
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
        dismissKeyboard()
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
        let internalLoginName = loginName.text
        let username = user.text
        loginViewModel.delegate = self
        loginViewModel.login(account: email, password: pass, login: internalLoginName,
                             userName: username) { (err) in
            if let error = err {
                handleLoginError(error: error)
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
                self.loginName.isHidden = false
                self.manualConfigButton.isHidden = false
                self.extendedLogin = true
        }))
        present(alertView, animated: true, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.loginName {
            self.user.becomeFirstResponder()
        } else if textField == self.user {
            self.emailAddress.becomeFirstResponder()
        } else if textField == self.emailAddress {
            self.password.becomeFirstResponder()
        } else if textField == self.password {
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
        case backToEmailList
        case manualConfigSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .manualConfigSegue:
            if
                let navVC = segue.destination as? UINavigationController,
                let vc = navVC.topViewController as? UserInfoTableViewController {
                vc.appConfig = appConfig
                vc.model.address = emailAddress.text
                vc.model.password = password.text
                vc.model.userName = user.text
            }
        default:
            break
        }
    }
}

extension LoginTableViewController: AccountVerificationResultDelegate {
    func didVerify(result: AccountVerificationResult) {
        GCD.onMain() {
            switch result {
            case .ok:
                // unwind back to INBOX on success
                self.performSegue(withIdentifier: .backToEmailList, sender: self)
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
