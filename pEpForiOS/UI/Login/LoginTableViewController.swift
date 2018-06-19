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
    case minimumLengthUsername
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
        case .minimumLengthUsername:
            return NSLocalizedString("Username must have more than 5 characters.",
                                     comment: "minimum username length")
        case .noConnectData:
            return NSLocalizedString("Internal error",
                                     comment: "Automated account setup error description")
        case .accountExistence:
            return NSLocalizedString("Account already exist", comment: "account exist error message")
        }
    }
 }

 protocol LoginTableViewControllerDelegate {
    func loginTableViewControllerDidCreateNewAccount(_ loginTableViewController: LoginTableViewController)
 }

 class LoginTableViewController: BaseTableViewController {
    var loginViewModel = LoginViewModel()
    var offerManualSetup = false
    var delegate: LoginTableViewControllerDelegate?

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

    /**
     The last account input as determined by LAS, and delivered via didVerify.
     */
    var lastAccountInput: AccountUserInput?

    override func didSetAppConfig() {
        super.didSetAppConfig()
        loginViewModel.messageSyncService = appConfig.messageSyncService
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loginViewModel.loginViewModelLoginErrorDelegate = self
        loginViewModel.loginViewModelOAuth2ErrorDelegate = self
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

        // color and spacing configurations
        self.tableView.contentInset = UIEdgeInsets(top: 30,left: 0,bottom: 0,right: 0)

        // clear cell color
        UserTableViewCell.backgroundColor = UIColor.clear
        emailTableViewCell.backgroundColor = UIColor.clear
        passwordTableViewCell.backgroundColor = UIColor.clear
        loginTableViewCell.backgroundColor = UIColor.clear
        manualConfigTableViewCell.backgroundColor = UIColor.clear

        // hide extended login fields
        manualConfigButton.isHidden = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginTableViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title:NSLocalizedString("Cancel", comment: "Login NavigationBar canel button title"),
            style:.plain, target:self,
            action:#selector(self.backButton))
    }

    @objc func backButton() {
        self.dismiss(animated: true, completion: nil)
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

    private func handleLoginError(error: Error, offerManualSetup: Bool) {
        Log.shared.error(component: #function, error: error)
        self.isCurrentlyVerifying = false
        guard let error = DisplayUserError(withError: error) else {
            // Do nothing. The error type is not suitable to bother the user with.
            return
        }
        let alertView = UIAlertController.pEpAlertController(title: error.title,
                                                             message:error.localizedDescription,
                                                             preferredStyle: .alert)
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString( "View log",
                comment: "Button for viewing the log on error"),
            style: .default, handler: { action in
                self.viewLog()
        }))
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "Ok",
                comment: "UIAlertAction ok after error"),
            style: .default, handler: {action in
                if offerManualSetup {
                    self.manualConfigButton.isHidden = false
                    self.offerManualSetup = true
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
            handleLoginError(error: LoginTableViewControllerError.missingEmail,
                             offerManualSetup: false)
            return
        }
        guard !loginViewModel.exist(address: email) else {
            isCurrentlyVerifying = false
            handleLoginError(error: LoginTableViewControllerError.accountExistence,
                             offerManualSetup: false)
            return
        }
        guard let username = user.text, username != ""  else {
            handleLoginError(error: LoginTableViewControllerError.missingUsername,
                             offerManualSetup: false)
            return
        }

        guard username.count > 4 else {
            handleLoginError(error: LoginTableViewControllerError.minimumLengthUsername,
                             offerManualSetup: false)
            return
        }

        loginViewModel.accountVerificationResultDelegate = self

        if loginViewModel.isOAuth2Possible(email: email) {
            let oauth = appConfig.oauth2AuthorizationFactory.createOAuth2Authorizer()
            loginViewModel.loginWithOAuth2(
                viewController: self, emailAddress: email, userName: username,
                mySelfer: appConfig.mySelfer, oauth2Authorizer: oauth)
        } else {
            guard let pass = password.text, pass != "" else {
                handleLoginError(error: LoginTableViewControllerError.missingPassword,
                                 offerManualSetup: false)
                return
            }

            loginViewModel.login(
                accountName: email, userName: username, password: pass,
                mySelfer: appConfig.mySelfer)
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

 // MARK: - UITextFieldDelegate

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

 // MARK: - SegueHandlerType

 extension LoginTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case noSegue
        case viewLogSegue
        case manualConfigSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .manualConfigSegue:
            if
                let navVC = segue.destination as? UINavigationController,
                let vc = navVC.topViewController as? UserInfoTableViewController {
                vc.appConfig = appConfig

                if let accountInput = lastAccountInput {
                    vc.model = accountInput // give the user some prefilled data in manual mode
                }

                // Overwrite with more recent data that we might have (in case it was changed)
                vc.model.address = emailAddress.text
                vc.model.password = password.text
                vc.model.userName = user.text
            }
        case .viewLogSegue:
            if let navVC = segue.destination as? UINavigationController,
                let vc = navVC.topViewController as? LogViewController {
                vc.appConfig = appConfig
                vc.navigationController?.navigationBar.isHidden = false
            }
        default:
            break
        }
    }
 }

 // MARK: - AccountVerificationResultDelegate

 extension LoginTableViewController: AccountVerificationResultDelegate {
    func didVerify(result: AccountVerificationResult, accountInput: AccountUserInput?) {
            GCD.onMain() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            me.lastAccountInput = nil
            switch result {
            case .ok:
                me.delegate?.loginTableViewControllerDidCreateNewAccount(me)
                me.navigationController?.dismiss(animated: true)
            case .imapError(let err):
                me.lastAccountInput = accountInput
                me.handleLoginError(error: err, offerManualSetup: true)
            case .smtpError(let err):
                me.lastAccountInput = accountInput
                me.handleLoginError(error: err, offerManualSetup: true)
            case .noImapConnectData, .noSmtpConnectData:
                me.lastAccountInput = accountInput
                me.handleLoginError(error: LoginTableViewControllerError.noConnectData,
                                       offerManualSetup: true)
            }
        }
    }
 }

 // MARK: - LoginViewModelLoginErrorDelegate

 extension LoginTableViewController: LoginViewModelLoginErrorDelegate {
    func handle(loginError: Error) {
        self.handleLoginError(error: loginError, offerManualSetup: true)
    }
 }

 // MARK: - LoginViewModelOAuth2ErrorDelegate

 extension LoginTableViewController: LoginViewModelOAuth2ErrorDelegate {
    func handle(oauth2Error: Error) {
        self.handleLoginError(error: oauth2Error, offerManualSetup: false)
    }
 }
