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

protocol LoginViewControllerDelegate: class  {
    func loginViewControllerDidCreateNewAccount(_ loginViewController: LoginViewController)
}

class LoginViewController: BaseViewController {
    static let minCharUserName = 1
    var loginViewModel: LoginViewModel?
    var offerManualSetup = false
    weak var delegate: LoginViewControllerDelegate?

    @IBOutlet var emailAddress: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var manualConfigButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var user: UITextField!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var mainContainerView: UIView!
    @IBOutlet weak var mainContainerViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewCenterYhCConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsViewCenterYhRConstraint: NSLayoutConstraint!

    @IBOutlet var stackView: UIStackView! //TODO: ALE remove if not used

    /// Set in prepare for segue, if the user selected an account with ouath from the menu
    var isOauthAccount = false {
        didSet {
            password.isHidden = isOauthAccount
        }
    }

    var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        configureView()
        configureAppearance()
        configureKeyboardAwareness()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    @objc func backButton() {
        self.dismiss(animated: true, completion: nil)
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
        guard !viewModelOrCrash().exist(address: email) else {
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

        viewModelOrCrash().accountVerificationResultDelegate = self

        if viewModelOrCrash().isOAuth2Possible(email: email) || isOauthAccount {
            let oauth = appConfig.oauth2AuthorizationFactory.createOAuth2Authorizer()
            viewModelOrCrash().loginWithOAuth2(
                viewController: self, emailAddress: email, userName: username,
                oauth2Authorizer: oauth)
        } else {
            guard let pass = password.text, pass != "" else {
                handleLoginError(error: LoginViewController.LoginError.missingPassword,
                                 offerManualSetup: false)
                return
            }

            viewModelOrCrash().login(
                accountName: email, userName: username, password: pass)
        }
    }

    @IBAction func emailChanged(_ sender: UITextField) {
        updatePasswordField(email: sender.text)
    }
}

// MARK: - View model

extension LoginViewController {
    func createViewModel() -> LoginViewModel {
        let theLoginViewModel = LoginViewModel(
            verifiableAccount: VerifiableAccount(
                messageModelService: appConfig.messageModelService))
        theLoginViewModel.loginViewModelLoginErrorDelegate = self
        theLoginViewModel.loginViewModelOAuth2ErrorDelegate = self
        return theLoginViewModel
    }

    func setupViewModel() {
        loginViewModel = createViewModel()
    }

    func viewModelOrCrash() -> LoginViewModel {
        if let theVM = loginViewModel {
            return theVM
        } else {
            Log.shared.errorAndCrash("No view model")
            return createViewModel()
        }
    }
}

// MARK: - Util

extension LoginViewController {
    func updatePasswordField(email: String?) {
        guard !isOauthAccount else { return }

        let oauth2Possible = viewModelOrCrash().isOAuth2Possible(email: email)
        password.isEnabled = !oauth2Possible

        if oauth2Possible {
            hidePasswordTextField()
        } else {
            showPasswordTextField()
        }
    }
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailAddress:
            password.becomeFirstResponder()
        case password:
            user.becomeFirstResponder()
        case user:
            user.resignFirstResponder()
            logIn(textField as Any)
        default:
            break
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        stackViewCenterYhCConstraint.constant = stackView.bounds.height / 2 - textField.center.y
        //        stackViewCenterYConstraint.constant += -(textField.center.y -  mainContainerView.center.y)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        stackViewCenterYhCConstraint.constant = 0
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            [weak self] in
            self?.view.layoutIfNeeded()
        })
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

                // Give the next model all that we know.
                vc.model = viewModelOrCrash().verifiableAccount
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
        handleLoginError(error: loginError, offerManualSetup: true)
    }
}

// MARK: - LoginViewModelOAuth2ErrorDelegate

extension LoginViewController: LoginViewModelOAuth2ErrorDelegate {
    func handle(oauth2Error: Error) {
        handleLoginError(error: oauth2Error, offerManualSetup: false)
    }
}

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

// MARK: - Private

extension LoginViewController {
    private func hidePasswordTextField() {
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: { [weak self] in
                        self?.password.alpha = 0
            }, completion: { [weak self] completed in
                guard completed else { return }
                UIView.animate(withDuration: 0.2) {
                    self?.password.isHidden = true
                }
        })
    }

    private func showPasswordTextField() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.password.isHidden = false
            }, completion: { [weak self] completed in
                guard completed else { return }
                UIView.animate(withDuration: 0.2,
                               delay: 0,
                               options: [.curveEaseInOut, .beginFromCurrentState],
                               animations: { [weak self] in
                                self?.password.alpha = 1.0
                    }, completion: nil)
        })
    }

    private func configureAppearance() {
        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            navigationItem.leftBarButtonItem?.tintColor = UIColor.white
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.backgroundColor = UIColor.clear
        }
    }

    private func handleLoginError(error: Error, offerManualSetup: Bool) {
        Log.shared.error("%@", "\(error)")
        isCurrentlyVerifying = false
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

    private func configureView() {
        password.isEnabled = true
        activityIndicatorView.hidesWhenStopped = true

        emailAddress.placeholder = NSLocalizedString("Email", comment: "Email")
        password.placeholder = NSLocalizedString("Password", comment: "password")
        user.placeholder = NSLocalizedString("Name", comment: "username")

        loginButton.convertToLoginButton(
            placeholder: NSLocalizedString("Sign In", comment: "Login"))
        manualConfigButton.convertToLoginButton(
            placeholder: NSLocalizedString("Manual configuration", comment: "manual"))

        navigationController?.navigationBar.isHidden = !viewModelOrCrash().isThereAnAccount()

        // hide extended login fields
        manualConfigButton.isHidden = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title:NSLocalizedString("Cancel", comment: "Login NavigationBar canel button title"),
            style:.plain, target:self,
            action:#selector(self.backButton))
    }

    private func updateView() {
        if isCurrentlyVerifying {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        navigationItem.rightBarButtonItem?.isEnabled = !isCurrentlyVerifying
        loginButton.isEnabled = !isCurrentlyVerifying
        manualConfigButton.isEnabled = !isCurrentlyVerifying
    }
}
