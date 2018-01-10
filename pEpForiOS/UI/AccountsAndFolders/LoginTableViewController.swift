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
    case missingUsername
    case accountExistence
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
        case .missingUsername:
            return NSLocalizedString("Username must not be empty.",
                                     comment: "Empty username message")
        case .noConnectData:
            return NSLocalizedString("Internal error",
                                     comment: "Automated account setup error description")
        case .accountExistence:
            return NSLocalizedString("account alredy exist", comment: "account exist error message")
        }
    }
 }

 class LoginTableViewController: BaseTableViewController {
    var loginViewModel = LoginViewModel()
    var extendedLogin = false

    @IBOutlet var emailAddress: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var manualConfigButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var user: UITextField!

    @IBOutlet var UserTableViewCell: UITableViewCell!
    @IBOutlet var emailTableViewCell: UITableViewCell!
    @IBOutlet var passwordTableViewCell: UITableViewCell!
    @IBOutlet var loginTableViewCell: UITableViewCell!
    @IBOutlet var manualConfigTableViewCell: UITableViewCell!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!

    var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    override func didSetAppConfig() {
        super.didSetAppConfig()
        loginViewModel.messageSyncService = appConfig.messageSyncService
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }

    func configureView(){
        UIHelper.variableCellHeightsTableView(self.tableView)

        password.isEnabled = true

        self.emailAddress.convertToLoginField(
            placeholder: NSLocalizedString("Email", comment: "Email"), delegate: self)
        self.password.convertToLoginField(
            placeholder: NSLocalizedString("Password", comment: "password"), delegate: self)
        self.loginButton.convertToLoginButton(
            placeholder: NSLocalizedString("Sign In", comment: "Login"))
        self.manualConfigButton.convertToLoginButton(
            placeholder: NSLocalizedString("Manual configuration", comment: "manual"))
        self.user.convertToLoginField(
            placeholder: NSLocalizedString("Name", comment: "username"), delegate: self)

        self.navigationController?.navigationBar.isHidden = !loginViewModel.isThereAnAccount()

        //color and spacing configurations
        let bgView = GradientView(colors: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        tableView.backgroundView = bgView
        self.tableView.contentInset = UIEdgeInsets(top: 30,left: 0,bottom: 0,right: 0)
        self.tableView.backgroundColor  = UIColor.pEpGreen

        //clear cell color
        UserTableViewCell.backgroundColor = UIColor.clear
        emailTableViewCell.backgroundColor = UIColor.clear
        passwordTableViewCell.backgroundColor = UIColor.clear
        loginTableViewCell.backgroundColor = UIColor.clear
        manualConfigTableViewCell.backgroundColor = UIColor.clear

        //hide extended login fields
        manualConfigButton.isHidden = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginTableViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title:"Cancel", style:.plain, target:self, action:#selector(self.backButton))
    }

    @objc func backButton() {
        self.navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        if isCurrentlyVerifying {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        navigationItem.rightBarButtonItem?.isEnabled = !isCurrentlyVerifying
        loginButton.isEnabled = !isCurrentlyVerifying
        manualConfigButton.isEnabled = !isCurrentlyVerifying
    }

    public func handleLoginError(error: Error, extended: Bool) {
        Log.shared.error(component: #function, error: error)
        let error = DisplayUserError(withError: error)
        self.isCurrentlyVerifying = false
        let alertView = UIAlertController(title: error.title,
                                          message:error.localizedDescription,
                                          preferredStyle: .alert)
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
                if extended {
                    self.manualConfigButton.isHidden = false
                    self.extendedLogin = true
                }
        }))
        present(alertView, animated: true, completion: nil)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func viewLog() {
        performSegue(withIdentifier: .viewLogSegue, sender: self)
    }

    // MARK: - IBAction

    @IBAction func logIn(_ sender: Any) {
        dismissKeyboard()
        isCurrentlyVerifying = true

        guard let email = emailAddress.text?.trimmedWhiteSpace(), email != "" else {
            handleLoginError(error: LoginTableViewControllerError.missingEmail, extended: false)
            return
        }
        guard !loginViewModel.exist(address: email) else {
            isCurrentlyVerifying = false
            handleLoginError(error: LoginTableViewControllerError.accountExistence, extended: false)
            return
        }
        guard let username = user.text, username != "" else {
            handleLoginError(error: LoginTableViewControllerError.missingUsername, extended: false)
            return
        }

        guard let pass = password.text, pass != "" else {
            handleLoginError(error: LoginTableViewControllerError.missingPassword, extended: false)
            return
        }

        loginViewModel.accountVerificationResultDelegate = self
        loginViewModel.login(
            accountName: email, password: pass, userName: username,
            mySelfer: appConfig.mySelfer) { [weak self] error in
                self?.handleLoginError(error: error, extended: true)
        }
    }

    @IBAction func emailChanged(_ sender: UITextField) {
        updatePasswordField(email: sender.text)
    }

    // MARK: - Util

    func updatePasswordField(email: String?) {
        let oauth2Possible = loginViewModel.isOAuth2Possible(email: email)
        password.isEnabled = !oauth2Possible
        if password.isEnabled {
            password.enableLoginField()
        } else {
            password.disableLoginField()
        }
    }
 }

 extension LoginTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.user {
            self.emailAddress.becomeFirstResponder()
        } else if textField == self.emailAddress {
            self.password.becomeFirstResponder()
        } else if textField == self.password {
            self.logIn(self.password)
        }
        return true
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
        case .viewLogSegue:
            if let navVC = segue.destination as? UINavigationController, let vc = navVC.topViewController as? LogViewController {
                vc.appConfig = appConfig
                vc.navigationController?.navigationBar.isHidden = false
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
                self.handleLoginError(error: err, extended: true)
            case .smtpError(let err):
                self.handleLoginError(error: err, extended: true)
            case .noImapConnectData, .noSmtpConnectData:
                self.handleLoginError(error: LoginTableViewControllerError.noConnectData, extended: true)
            }
        }
    }
 }
