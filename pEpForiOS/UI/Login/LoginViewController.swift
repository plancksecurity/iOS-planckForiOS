//
//  LoginViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 13/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox
import MessageModel

protocol LoginViewControllerDelegate: AnyObject  {
    func loginViewControllerDidCreateNewAccount(_ loginViewController: LoginViewController)
}

final class LoginViewController: UIViewController {

    @IBOutlet weak var leadingZero: NSLayoutConstraint!
    public weak var delegate: LoginViewControllerDelegate?

    @IBOutlet private weak var pepSyncLabel: UILabel!
    @IBOutlet private weak var syncStackView: UIStackView!
    @IBOutlet private weak var user: AnimatedPlaceholderTextfield!
    @IBOutlet private weak var password: AnimatedPlaceholderTextfield!
    @IBOutlet private weak var emailAddress: AnimatedPlaceholderTextfield!
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var dismissButtonLeft: UIButton!
    @IBOutlet private weak var loginButtonIPadLandscape: UIButton!
    @IBOutlet private weak var manualConfigButton: TwoLinesButton!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var scrollView: DynamicHeightScrollView!
    @IBOutlet private weak var pEpSyncSwitch: UISwitch!

    // Constraints
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var pEpSyncViewCenterHConstraint: NSLayoutConstraint!
    @IBOutlet private weak var loginButtonCenterXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var loginButtonTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var centerX: NSLayoutConstraint!
    @IBOutlet weak var manualSetupWidth: NSLayoutConstraint!

    var viewModel: LoginViewModel?
    private var offerManualSetup = false

    @IBOutlet weak var pepSyncLeadingBiggerThan: NSLayoutConstraint!
    private var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setFonts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        updateView()
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        if vm.isCloud() {
            showiCloudAlert()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setManualSetupButtonHidden(manualConfigButton.isHidden)
        syncStackView.axis = UIDevice.isSmall && UIDevice.isLandscape ? .vertical : .horizontal
        syncStackView.superview?.layoutIfNeeded()
        manualConfigButton.contentHorizontalAlignment = UIDevice.isPortrait ? .right : .left
        setLoginButtonPosition()
    }

    private func setLoginButtonPosition() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        if vm.isThereAnAccount() {
            loginButtonCenterXConstraint.isActive = false
            loginButtonTrailingConstraint.isActive = true
        } else {
            if UIDevice.isLandscape {
                loginButtonCenterXConstraint.isActive = false
            } else {
                loginButtonCenterXConstraint.isActive = true
            }
            loginButtonTrailingConstraint.isActive = false
        }
        loginButton.contentHorizontalAlignment = UIDevice.isPortrait ? .right : .left
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

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        vm.accountVerificationResultDelegate = self

        guard let email = emailAddress.text?.trimmed(), !email.isEmpty else {
            handleLoginError(error: LoginViewController.LoginError.missingEmail,
                             offerManualSetup: false)
            return
        }

        // Allow _any_ email address, don't check anything
        // (was calling `email.isProbablyValidEmail` and reporting
        // `LoginViewController.LoginError.invalidEmail` in case).

        guard !vm.exist(address: email) else {
            isCurrentlyVerifying = false
            handleLoginError(error: LoginViewController.LoginError.accountExistence,
                             offerManualSetup: false)
            return
        }

        guard let userName = user.text else {
            Log.shared.errorAndCrash("Found nil text in user.text")
            handleLoginError(error: LoginViewController.LoginError.missingUsername,
                             offerManualSetup: true)
            return
        }

        guard let pass = password.text, !pass.isEmpty else {
            handleLoginError(error: LoginViewController.LoginError.missingPassword,
                             offerManualSetup: false)
            return
        }

        vm.login(emailAddress: email,
                 displayName: userName,
                 password: pass)
    }

    func firstResponderTextField() -> UITextField? {
        if emailAddress.isFirstResponder {
            return emailAddress
        }
        if password.isFirstResponder {
            return password
        }
        if user.isFirstResponder {
            return user
        }
        return nil
    }
}

// MARK: - View model

extension LoginViewController {

    func setupViewModel() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.loginViewModelLoginErrorDelegate = self

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

        let item = textField.inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []

        scrollView.scrollAndMakeVisible(textField)
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if UIDevice.current.userInterfaceIdiom != .pad {
            scrollView.scrollAndMakeVisible(textField)
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        switch textField {
        case emailAddress:
            vm.loginUtil.verifiableAccount.address = textField.text
        case password:
            vm.loginUtil.verifiableAccount.imapPassword = textField.text
            vm.loginUtil.verifiableAccount.smtpPassword = textField.text
        case user:
            vm.loginUtil.verifiableAccount.userName = textField.text
        default:
            Log.shared.errorAndCrash("Unhandled case")
        }
    }
}

// MARK: - SegueHandlerType

extension LoginViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case noSegue
        case manualConfigSegue
        case clientCertManagementSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        switch segueIdentifier(for: segue) {
        case .manualConfigSegue:
            guard let navVC = segue.destination as? UINavigationController,
                let vc = navVC.topViewController as? UserInfoViewController else {
                    Log.shared.errorAndCrash("fail to cast to UserInfoViewController")
                    return
            }
            // Give the next model all that we know.
            vc.verifiableAccount = vm.loginUtil.verifiableAccount
        default:
            Log.shared.errorAndCrash("Unhandled segue type")
            return
        }
    }
}

// MARK: - AccountVerificationResultDelegate

extension LoginViewController: AccountVerificationResultDelegate {
    func didVerify(result: AccountVerificationResult) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
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
            case .unknown(let err):
                me.handleLoginError(error: err, offerManualSetup: true)
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

extension LoginViewController {
    enum LoginError: Error {
        case missingEmail
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
            return NSLocalizedString("A valid email address is required",
                                     comment: "error message for .missingEmail")
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

// MARK: - DynamicHeightScrollViewDelegate

extension LoginViewController: DynamicHeightScrollViewDelegate {
    var firstResponder: UIView? {
        get { firstResponderTextField() }
    }

    var bottomConstraint: NSLayoutConstraint {
        get { scrollViewBottomConstraint }
    }
}

// MARK: - Private

extension LoginViewController {

    private func setup() {
        setupViewModel()
        configureView()
        configureAppearance()
        setManualSetupButtonHidden(true)
    }

    private func configureAppearance() {
        Appearance.customiseForLogin(viewController: self)
        navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        
    }

    private func handleLoginError(error: Error, offerManualSetup: Bool) {
        Log.shared.log(error: error)
        isCurrentlyVerifying = false

        guard let displayError = DisplayUserError(withError: error) else {
            // Do nothing. The error type is not suitable to bother the user with.
            return
        }

        let title = displayError.title
        let message = displayError.errorDescription

        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.setManualSetupButtonHidden(!offerManualSetup)
        }
    }

    private func configureView() {
        loginButton.convertToLoginButton(
            placeholder: NSLocalizedString("Log In",
                                           comment: "Log in button in Login View"))
        loginButton.accessibilityIdentifier = AccessibilityIdentifier.loginButton

        loginButtonIPadLandscape.convertToLoginButton(
            placeholder: NSLocalizedString("Log In",
                                           comment: "Log in button in Login View"))
        loginButtonIPadLandscape.accessibilityIdentifier = AccessibilityIdentifier.loginButton

        manualConfigButton.convertToLoginButton(
            placeholder: NSLocalizedString("Manual setup",
                                           comment: "Manual Setup button in Login View"))
        manualConfigButton.accessibilityIdentifier = AccessibilityIdentifier.manualConfigButton

        dismissButtonLeft.convertToLoginButton(
            placeholder: NSLocalizedString("Cancel",
                                           comment: "Cancel in button in Login View"))
        dismissButtonLeft.accessibilityIdentifier = AccessibilityIdentifier.cancelButton

        dismissButton.convertToLoginButton(
            placeholder: NSLocalizedString("Cancel",
                                           comment: "Cancel in button in Login View"))
        dismissButton.accessibilityIdentifier = AccessibilityIdentifier.cancelButton

        pEpSyncSwitch.onTintColor = UIColor(hexString: "#58FF75")
        pEpSyncSwitch.accessibilityIdentifier = AccessibilityIdentifier.pEpSyncSwitch

        // hide extended login fields
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        setManualSetupButtonHidden(true)
        hideSpecificDeviceButton()
        configureAnimatedTextFields()

        scrollView.dynamicHeightScrollViewDelegate = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideSpecificDeviceButton),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    private func configureAnimatedTextFields() {
        user.textColorWithText = UIColor.primary()
        user.placeholder = NSLocalizedString("Display Name",
                                             comment: "Display Name TextField Placeholder in Login Screen")
        user.accessibilityIdentifier = AccessibilityIdentifier.displayNameTextField

        password.textColorWithText = UIColor.primary()
        password.placeholder = NSLocalizedString("Password",
                                                 comment: "Password TextField Placeholder in Login Screen")
        password.accessibilityIdentifier = AccessibilityIdentifier.passwordTextField


        emailAddress.textColorWithText = UIColor.primary()
        emailAddress.placeholder = NSLocalizedString("Email Address",
                                                     comment: "Email TextField Placeholder in Login Screen")
        emailAddress.accessibilityIdentifier = AccessibilityIdentifier.emailAddressTextField

    }

    @objc private func hideSpecificDeviceButton() {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
        let isIPhoneLandscape = isIPhone && isLandscape()
        let isIpadLandscape = isIpad && isLandscape()
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        let hideCancelButtons = !vm.isThereAnAccount()

        loginButton.isHidden = isIpadLandscape
        loginButtonIPadLandscape.isHidden = !isIpadLandscape

        if hideCancelButtons {
            dismissButton.isHidden = true
            dismissButtonLeft.isHidden = true
        } else {
            dismissButton.isHidden = isIpadLandscape || isIPhoneLandscape
            dismissButtonLeft.isHidden = !(isIpadLandscape || isIPhoneLandscape)
        }
    }

    private func setManualSetupButtonHidden(_ hidden: Bool) {
        let hasChanged = manualConfigButton.isHidden != hidden
        manualConfigButton.isHidden = hidden
        if UIDevice.isPortrait || (UIDevice.isIpad && UIDevice.isLandscape) {
            pEpSyncViewCenterHConstraint.isActive = hidden
            centerX.isActive = hidden
            leadingZero.isActive = !hidden
            pepSyncLeadingBiggerThan.isActive = hidden
            manualSetupWidth.isActive = hidden

            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let me = self else {
                    //Valid case: might be dismmissed already
                    return
                }
                if hasChanged {
                    me.view.layoutIfNeeded()
                }
            }
        }
    }

    private func updateView() {
        if isCurrentlyVerifying {
            LoadingInterface.showLoadingInterface()
        } else {
            LoadingInterface.removeLoadingInterface()
        }
        navigationController?.navigationBar.isHidden = false
        navigationItem.hidesBackButton = false

        dismissButton.isEnabled = !isCurrentlyVerifying
        dismissButtonLeft.isEnabled = !isCurrentlyVerifying

        loginButton.isEnabled = !isCurrentlyVerifying
        manualConfigButton.isEnabled = !isCurrentlyVerifying
        pEpSyncSwitch.onTintColor = UIColor.primary()
    }

    private func isLandscape() -> Bool {
        if UIDevice.current.orientation.isFlat  {
            return UIApplication.shared.statusBarOrientation.isLandscape
        } else {
            return UIDevice.current.orientation.isLandscape
        }
    }
}

// MARK: - iCloud alert

extension LoginViewController {
    private func showiCloudAlert() {
        func openiCloudInfoInBrowser() {
            let urlString = "https://support.apple.com/en-us/HT204174"
            guard let url = URL(string: urlString) else {
                Log.shared.errorAndCrash(message: "Not a URL? \(urlString)")
                return
            }
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
        UIUtils.showTwoButtonAlert(withTitle: NSLocalizedString("iCloud", comment: "Alert title for iCloud instructions"),
                                   message: NSLocalizedString("You need to create an app-specific password in your iCloud account.", comment: "iCloud instructions"),
                                   cancelButtonText: NSLocalizedString("OK", comment: "OK (dismiss) button for iCloud instructions alert"),
                                   positiveButtonText: NSLocalizedString("Info", comment: "Info button for showing iCloud page"),
                                   cancelButtonAction: {},
                                   positiveButtonAction: openiCloudInfoInBrowser)
    }
}
// MARK: - Accessibility

extension LoginViewController {

    private func setFonts() {
        emailAddress.font = UIFont.planckFont(style: .callout, weight: .regular)
        password.font = UIFont.planckFont(style: .callout, weight: .regular)
        user.font = UIFont.planckFont(style: .callout, weight: .regular)
        loginButton.setPEPFont(style: .body, weight: .regular)
        dismissButton.setPEPFont(style: .body, weight: .regular)
        manualConfigButton.setPEPFont(style: .callout, weight: .regular)
        dismissButtonLeft.setPEPFont(style: .body, weight: .regular)
        loginButtonIPadLandscape.setPEPFont(style: .body, weight: .regular)
        pepSyncLabel.setPEPFont(style: .callout, weight: .regular)
    }
}

extension LoginViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            view.layoutIfNeeded()
        }
    }
}
