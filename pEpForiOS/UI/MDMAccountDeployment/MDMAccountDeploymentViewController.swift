//
//  MDMAccountDeploymentViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox
import MessageModel

class MDMAccountDeploymentViewController: UIViewController, UITextFieldDelegate {
    // MARK: - Storyboard

    @IBOutlet weak var stackView: UIStackView!

    private var accountData: MDMAccountDeploymentViewModel.AccountData?
    let viewModel = MDMAccountDeploymentViewModel()
    weak var loginDelegate: LoginViewControllerDelegate?

    var textFieldPassword: UITextField?
    var buttonVerify: UIButton?
    var loginSpinner: UIActivityIndicatorView?
    

    /// An optional label containing the last error message.
    var errorLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.accountTypeSelectorViewModel.delegate = self
        setupUI()

        // Prevent the user to be able to "swipe down" this VC
        isModalInPresentation = true

        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let accountData = accountData, let provider = accountData.oauthProvider {
            handleOAuth(oauthProvider: provider)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let passwordTF = textFieldPassword {
            passwordTF.becomeFirstResponder()
        }
     }

    // MARK: - Build the UI

    func setupUI() {
        let existingArrangedViews = stackView.arrangedSubviews
        stackView.removeArrangedSubviews()
        stackView.alignment = .center
        stackView.spacing = 10

        for view in existingArrangedViews {
            view.removeFromSuperview()
        }

        switch viewModel.uiState() {
        case .noAccountConfiguration(let errorMessage):
            setError(message: errorMessage)
        case .accountData(let accountData):
            self.accountData = accountData
            let accountLabel = UILabel()
            accountLabel.text = accountData.accountName
            accountLabel.setPEPFont(style: .title1, weight: .regular)

            let emailLabel = UILabel()
            emailLabel.text = accountData.email
            emailLabel.setPEPFont(style: .title1, weight: .regular)

            let passwordInput = UITextField()
            passwordInput.placeholder = viewModel.passwordTextFieldPlaceholderText()
            passwordInput.isSecureTextEntry = true
            passwordInput.delegate = self
            passwordInput.addTarget(self,
                                    action: #selector(textFieldDidChange),
                                    for: .editingChanged)
            textFieldPassword = passwordInput

            let button = UIButton(type: .system)
            button.setTitle(viewModel.verifyButtonTitleText(), for: .normal)
            button.addTarget(self, action: #selector(deployButtonTapped), for: .touchUpInside)
            button.isEnabled = false
            buttonVerify = button

            let loginSpinner = UIActivityIndicatorView(style: .medium)
            loginSpinner.hidesWhenStopped = true
            loginSpinner.isHidden = true
            self.loginSpinner = loginSpinner

            stackView.addArrangedSubview(accountLabel)
            stackView.addArrangedSubview(emailLabel)
            if let oauthProvider = accountData.oauthProvider {
                textFieldPassword?.isHidden = true
                loginSpinner.isHidden = false
                stackView.addArrangedSubview(loginSpinner)
            } else {
                stackView.addArrangedSubview(passwordInput)
                stackView.addArrangedSubview(button)
            }
        }

        configureView()
    }

    // MARK: - Actions

    func handleOAuth(oauthProvider: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let me = self else {
                return
            }
            me.loginSpinner?.startAnimating()
            if oauthProvider == OAuthProvider.microsoft.rawValue {
                me.viewModel.handleDidSelect(accountType: .microsoft, viewController: me)
            } else if oauthProvider == OAuthProvider.google.rawValue {
                me.viewModel.handleDidSelect(accountType: .google, viewController: me)
            } else {
                Log.shared.errorAndCrash("OAuth provider not supported")
            }
        })
    }

    @objc func deployButtonTapped() {
        deploy()
    }
    
    @objc func textFieldDidChange(textField: UITextField) {
        guard let verifyButton = buttonVerify else {
            // No button, nothing to do
            return
        }

        let charCount = textField.text?.count ?? 0
        if charCount > 0 {
            verifyButton.isEnabled = true
        } else {
            verifyButton.isEnabled = false
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        deploy()
        return true
    }

    // MARK: - Deploy

    /// The version that gets called from the UI.
    func deploy() {
        guard let textField = textFieldPassword else {
            Log.shared.errorAndCrash(message: "Deploy button tapped, but no password text field")
            return
        }

        guard let password = textField.text else {
            Log.shared.errorAndCrash(message: "Deploy button tapped, but empty password text field")
            return
        }

        deploy(password: password)
    }

    func deploy(password: String) {
        func enableUI(enabled: Bool) {
            buttonVerify?.isEnabled = enabled
            textFieldPassword?.isEnabled = enabled
        }

        enableUI(enabled: false)

        // Remove any error from previous attempts
        unsetError()

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        stackView.addArrangedSubview(activityIndicator)

        viewModel.deployAccount(password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let theSelf = self else {
                    Log.shared.lostMySelf()
                    return
                }

                theSelf.stackView.removeArrangedSubview(activityIndicator)
                activityIndicator.removeFromSuperview()

                switch result {
                case .error(let message):
                    let errorMessage = theSelf.viewModel.errorMessage(message: message)
                    theSelf.setError(message: errorMessage)

                    enableUI(enabled: true)

                    break
                case .success:
                    theSelf.navigationController?.dismiss(animated: true)
                }
            }
        }
    }

    // MARK: - Error Message

    func setError(message: String) {
        if let existing = errorLabel {
            existing.text = message
        } else {
            let newErrorLabel = UILabel()
            newErrorLabel.lineBreakMode = .byWordWrapping
            newErrorLabel.numberOfLines = 0
            newErrorLabel.text = message
            newErrorLabel.textAlignment = .center
            stackView.insertArrangedSubview(newErrorLabel, at: 0)
            errorLabel = newErrorLabel
        }
    }

    func unsetError() {
        if let existing = errorLabel {
            stackView.removeArrangedSubview(existing)
            existing.removeFromSuperview()
            errorLabel = nil
        }
    }

    // MARK: - Font Size

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Here we react to changes in the font size.
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureView()
        }
    }

    private func configureView() {
        view.setNeedsLayout()
    }
}

// MARK: - OAuth

extension MDMAccountDeploymentViewController: AccountTypeSelectorViewModelDelegate {
    func showMustImportClientCertificateAlert() {
        //N/A
    }
    
    func showClientCertificateSeletionView() {
        //N/A
    }
    
    func didVerify(result: AccountVerificationResult) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.resignFirstResponder()
            me.view.endEditing(true)
            me.loginSpinner?.stopAnimating()
            switch result {
            case .ok:
                me.loginDelegate?.loginViewControllerDidCreateNewAccount(LoginViewController())
                me.navigationController?.dismiss(animated: true)
            case .imapError(let err):
                Log.shared.error(error: err)
            case .smtpError(let err):
                Log.shared.error(error: err)
            case .noImapConnectData, .noSmtpConnectData:
                me.handleLoginError(error: LoginViewController.LoginError.noConnectData)
            }
        }
    }

    func handle(oauth2Error: Error) {
        handleLoginError(error: oauth2Error)
    }
}

// MARK: - OAuth Error handling

extension MDMAccountDeploymentViewController {
    private func handleLoginError(error: Error) {
        loginSpinner?.stopAnimating()
        Log.shared.log(error: error)

        let title = NSLocalizedString("Invalid Address",
                                      comment: "Please enter a valid Gmail address.Fail to log in, email does not match account type")
        var message: String?

        switch viewModel.accountTypeSelectorViewModel.loginUtil.verifiableAccount.accountType {
        case .gmail:
            message = NSLocalizedString("Please enter a valid Gmail address.",
                                        comment: "Fail to log in, email does not match account type")
        case .o365:
            message = NSLocalizedString("Please enter a valid Microsoft address.",
                                        comment: "Fail to log in, email does not match account type")
        default:
            Log.shared.errorAndCrash("Login should not do oauth with other email address")
        }
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message)
    }
}
