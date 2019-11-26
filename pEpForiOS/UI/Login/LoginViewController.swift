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

    weak var delegate: LoginViewControllerDelegate?

    @IBOutlet weak var user: AnimatedPlaceholderTextfield!
    @IBOutlet weak var password: AnimatedPlaceholderTextfield!
    @IBOutlet weak var emailAddress: AnimatedPlaceholderTextfield!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var loginButtonIPadLandscape: UIButton!
    @IBOutlet weak var manualConfigButton: UIButton!
    @IBOutlet weak var mainContainerView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var pEpSyncViewCenterHConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginButtonCenterYConstraint: NSLayoutConstraint!

    var loginViewModel: LoginViewModel?
    var offerManualSetup = false
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

        //TODO: ALE BORRAR
        setManualSetupButtonHidden(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    @IBAction func dismissButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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

    @IBAction func pEpSyncStateChanged(_ sender: UISwitch) {
        loginViewModel?.isAccountPEPSyncEnable = sender.isOn
    }


    func scrollAndMakeVisible(_ textField: UITextField, scrollViewHeight: CGFloat) {
        let textFieldFrames = textField.convert(textField.bounds, to: scrollView)
        var newContentOffSet = textFieldFrames.midY - scrollViewHeight / 2
        let contetOffSetDistanceToSafeArea =
            scrollView.contentSize.height - newContentOffSet - scrollViewHeight

        //Add padding if can not scroll enough
        if newContentOffSet < 0 {
            scrollView.contentInset.top = abs(newContentOffSet)
        } else if contetOffSetDistanceToSafeArea < 0 {
            scrollView.contentInset.bottom = abs(contetOffSetDistanceToSafeArea)
            newContentOffSet = scrollView.contentSize.height
                - scrollViewHeight
                + abs(contetOffSetDistanceToSafeArea)
        }

        DispatchQueue.main.async { [weak self] in
            self?.scrollView.setContentOffset(CGPoint(x: 0, y: newContentOffSet), animated: true)
        }
    }

    func scrollToCenterStackView() {
        let newContentOffSet = stackView.frame.midY - scrollView.bounds.height / 2
        DispatchQueue.main.async { [weak self] in
            self?.scrollView.setContentOffset(CGPoint(x: 0, y: newContentOffSet), animated: true)
        }
    }
}

// MARK: - View model

extension LoginViewController {
    func createViewModel() -> LoginViewModel {
        let theLoginViewModel = LoginViewModel(verifiableAccount: VerifiableAccount())
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
        case emailAddress where !password.isHidden:
            password.becomeFirstResponder()
        case password,
             emailAddress where password.isHidden:
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
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        //If is iOS13+ then this will be trigger in keyboard will appear
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 13,
                                                                          minorVersion: 0,
                                                                          patchVersion: 0)) {
            scrollAndMakeVisible(textField, scrollViewHeight: scrollView.frame.maxY)
        }
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
            guard let navVC = segue.destination as? UINavigationController,
                let vc = navVC.topViewController as? UserInfoTableViewController else {
                    Log.shared.errorAndCrash("fail to cast to UserInfoTableViewController")
                    return
            }
            vc.appConfig = appConfig

            // Give the next model all that we know.
            vc.model = viewModelOrCrash().verifiableAccount
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
            LoadingInterface.removeLoadingInterface()
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
            style: .default, handler: { [weak self] action in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.setManualSetupButtonHidden(!offerManualSetup)
        }))
        present(alertView, animated: true, completion: nil)
    }

    private func configureView() {
        password.isEnabled = true

        loginButton.convertToLoginButton(
            placeholder: NSLocalizedString("Sign In", comment: "Login"))
        manualConfigButton.convertToLoginButton(
            placeholder: NSLocalizedString("Manual configuration", comment: "manual"))

        // hide extended login fields
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollView.isScrollEnabled = false
        }
        setManualSetupButtonHidden(true)
        hideSpecificDeviceButton()
        configureAnimatedTextFields()

        dismissButton.isHidden = !viewModelOrCrash().isThereAnAccount()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideSpecificDeviceButton),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    private func configureAnimatedTextFields() {
        user.textColorWithText = .pEpGreen
        user.placeholder = NSLocalizedString("Name", comment: "username")

        password.textColorWithText = .pEpGreen
        password.placeholder = NSLocalizedString("Password", comment: "password")

        emailAddress.textColorWithText = .pEpGreen
        emailAddress.placeholder = NSLocalizedString("Email", comment: "Email")
    }

    @objc private func hideSpecificDeviceButton() {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        let isIpadLandscape = isIpad && isLandscape

        loginButton.isHidden = isIpadLandscape
        loginButtonIPadLandscape.isHidden = !isIpadLandscape
    }

    private func setManualSetupButtonHidden(_ hidden: Bool) {
        guard manualConfigButton.isHidden != hidden else { return }
        manualConfigButton.isHidden = hidden
        pEpSyncViewCenterHConstraint.constant = hidden ? 0 : -stackView.bounds.midX/2
        manualConfigButton.alpha = hidden ? 1 : 0

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
                        guard let me = self else {
                            Log.shared.lostMySelf()
                            return
                        }
                        me.manualConfigButton.alpha = hidden ? 0 : 1
                        me.mainContainerView.layoutIfNeeded()
        })
    }

    private func updateView() {
        if isCurrentlyVerifying {
            LoadingInterface.showLoadingInterface()
        } else {
            LoadingInterface.removeLoadingInterface()
        }

        navigationController?.navigationBar.isHidden = true

        dismissButton.isEnabled = !isCurrentlyVerifying

        loginButton.isEnabled = !isCurrentlyVerifying
        manualConfigButton.isEnabled = !isCurrentlyVerifying
    }
}
