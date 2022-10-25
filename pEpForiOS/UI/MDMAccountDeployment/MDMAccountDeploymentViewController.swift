//
//  MDMAccountDeploymentViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

class MDMAccountDeploymentViewController: UIViewController {
    // MARK: - Storyboard

    @IBOutlet weak var stackView: UIStackView!

    let viewModel = MDMAccountDeploymentViewModel()

    var textFieldPassword: UITextField?
    var buttonVerify: UIButton?

    /// An optional label containing the last error message.
    var errorLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        if #available(iOS 13.0, *) {
            // Prevent the user to be able to "swipe down" this VC
            isModalInPresentation = true
        } else {
            // Modal is modal already?
        }

        navigationController?.setNavigationBarHidden(true, animated: false)
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

        switch viewModel.uiState {
        case .initial:
            guard let accountData = viewModel.accountData() else {
                break
            }

            let accountLabel = UILabel()
            accountLabel.text = accountData.accountName
            accountLabel.setPEPFont(style: .title1, weight: .regular)

            let emailLabel = UILabel()
            emailLabel.text = accountData.email
            emailLabel.setPEPFont(style: .title1, weight: .regular)

            let passwordInput = UITextField()
            passwordInput.placeholder = viewModel.passwordTextFieldPlaceholderText()
            passwordInput.isSecureTextEntry = true
            passwordInput.addTarget(self,
                                    action: #selector(textFieldDidChange),
                                    for: .editingChanged)
            textFieldPassword = passwordInput

            let button = UIButton(type: .system)
            button.setTitle(viewModel.verifyButtonTitleText(), for: .normal)
            button.addTarget(self, action: #selector(deployButtonTapped), for: .touchUpInside)
            button.isEnabled = false
            buttonVerify = button

            stackView.addArrangedSubview(accountLabel)
            stackView.addArrangedSubview(emailLabel)
            stackView.addArrangedSubview(passwordInput)
            stackView.addArrangedSubview(button)
        }

        configureView()
    }

    // MARK: - Actions

    @objc func deployButtonTapped() {
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

    // MARK: - Deploy

    func deploy(password: String) {
        func enableUI(enabled: Bool) {
            buttonVerify?.isEnabled = enabled
            textFieldPassword?.isEnabled = enabled
        }

        func createActivityIndicator() -> UIActivityIndicatorView {
            if #available(iOS 13.0, *) {
                return UIActivityIndicatorView(style: .large)
            } else {
                return UIActivityIndicatorView(style: .whiteLarge)
            }
        }

        enableUI(enabled: false)

        // Remove any error from previous attempts
        unsetError()

        let activityIndicator = createActivityIndicator()
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
