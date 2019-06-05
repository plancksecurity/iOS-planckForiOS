//
//  LoginViewController.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 13/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel

extension LoginViewController {
    enum LoginError: Error {
        case missingEmail
        case invalidEmail
        case missingPassword
        case noConnectData
        case missingUsername
        case minimumLengthUsername
        case accountExistence
    }
}

extension LoginViewController.LoginError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingEmail:
            return NSLocalizedString("A valid email is required",
                                     comment: "error message for .missingEmail")
        case .invalidEmail:
            return NSLocalizedString("A valid email is required",
                                     comment: "error message for .invalidEmail")
        case .missingPassword:
            return NSLocalizedString("A non-empty password is required",
                                     comment: "error message for .missingPassword")
        case .missingUsername:
            return NSLocalizedString("A non-empty username is required",
                                     comment: "error message for .missingUsername")
        case .minimumLengthUsername:
            return NSLocalizedString("The username must contain more than 1 characters",
                                     comment: "error message for .minimumLengthUsername")
        case .noConnectData:
            return NSLocalizedString("An internal error occurred",
                                     comment: "error message for .noConnectData")
        case .accountExistence:
            return NSLocalizedString("The account already exists",
                                     comment: "error message for .accountExistence")
        }
    }
}

protocol LoginViewControllerDelegate: class  {
    func loginViewControllerDidCreateNewAccount(_ loginViewController: LoginViewController)
}

class LoginViewController: BaseViewController {
    static let minCharUserName = 1
    var loginViewModel = LoginViewModel()
    var offerManualSetup = false
    weak var delegate: LoginViewControllerDelegate?

    @IBOutlet var emailAddress: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var manualConfigButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var user: UITextField!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet var textFieldsContainerView: UIView!
    @IBOutlet var contentScrollView: UIScrollView!

    var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didSetAppConfig() {
        super.didSetAppConfig()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loginViewModel.loginViewModelLoginErrorDelegate = self
        loginViewModel.loginViewModelOAuth2ErrorDelegate = self
        configureView()
        configureKeyboardAwareness()
    }

    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }

    func configureView(){

        password.isEnabled = true
        activityIndicatorView.hidesWhenStopped = true

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

        // hide extended login fields
        manualConfigButton.isHidden = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title:NSLocalizedString("Cancel", comment: "Login NavigationBar canel button title"),
            style:.plain, target:self,
            action:#selector(self.backButton))

        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
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
        os_log(type: .error, "%{public}@", error.localizedDescription)
        self.isCurrentlyVerifying = false
        guard let error = DisplayUserError(withError: error) else {
            // Do nothing. The error type is not suitable to bother the user with.
            return
        }
        let alertView = UIAlertController.pEpAlertController(title: error.title,
                                                             message:error.localizedDescription,
                                                             preferredStyle: .alert)
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "OK",
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

    // MARK: - IBAction

    @IBAction func logIn(_ sender: Any) {
        dismissKeyboard()
        isCurrentlyVerifying = true

        guard let email = emailAddress.text?.trimmed(), email != "" else {
            handleLoginError(error: LoginViewController.LoginError.missingEmail,
                             offerManualSetup: false)
            return
        }
        guard email.isProbablyValidEmail() else {
            handleLoginError(error: LoginViewController.LoginError.invalidEmail,
                             offerManualSetup: false)
            return
        }
        guard !loginViewModel.exist(address: email) else {
            isCurrentlyVerifying = false
            handleLoginError(error: LoginViewController.LoginError.accountExistence,
                             offerManualSetup: false)
            return
        }
        guard let username = user.text, username != ""  else {
            handleLoginError(error: LoginViewController.LoginError.missingUsername,
                             offerManualSetup: false)
            return
        }

        guard username.count >= LoginViewController.minCharUserName else {
            handleLoginError(error: LoginViewController.LoginError.minimumLengthUsername,
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
                handleLoginError(error: LoginViewController.LoginError.missingPassword,
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

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.user {
            self.emailAddress.becomeFirstResponder()
        } else if textField == self.emailAddress {
            self.password.becomeFirstResponder()
        } else if textField == self.password {
            textField.resignFirstResponder()
            self.logIn(self.password)
        }
        return true
    }
}

// MARK: - SegueHandlerType

extension LoginViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case noSegue
        case manualConfigSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .manualConfigSegue:
            if
                let navVC = segue.destination as? UINavigationController,
                let vc = navVC.topViewController as? UserInfoTableViewController {
                vc.appConfig = appConfig

                // Give the next model what we know.
                vc.model.address = emailAddress.text
                vc.model.password = password.text
                vc.model.userName = user.text
            }
        default:
            break
        }
    }
}

// MARK: - AccountVerificationResultDelegate

extension LoginViewController: AccountVerificationResultDelegate {
    func didVerify(result: AccountVerificationResult) {
        GCD.onMain() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            switch result {
            case .ok:
                me.delegate?.loginViewControllerDidCreateNewAccount(me)
                me.navigationController?.dismiss(animated: true)
            case .imapError(let err):
                me.handleLoginError(error: err, offerManualSetup: true)
            case .smtpError(let err):
                me.handleLoginError(error: err, offerManualSetup: true)
            case .noImapConnectData, .noSmtpConnectData:
                me.handleLoginError(error: LoginViewController.LoginError.noConnectData,
                                    offerManualSetup: true)
            }
        }
    }
}

// MARK: - LoginViewModelLoginErrorDelegate

extension LoginViewController: LoginViewModelLoginErrorDelegate {
    func handle(loginError: Error) {
        self.handleLoginError(error: loginError, offerManualSetup: true)
    }
}

// MARK: - LoginViewModelOAuth2ErrorDelegate

extension LoginViewController: LoginViewModelOAuth2ErrorDelegate {
    func handle(oauth2Error: Error) {
        self.handleLoginError(error: oauth2Error, offerManualSetup: false)
    }
}
