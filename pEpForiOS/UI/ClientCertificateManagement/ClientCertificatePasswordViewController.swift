//
//  ClientCertificatePasswordViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class ClientCertificatePasswordViewController: UIViewController {

// MARK: - IBOutlet

    @IBOutlet weak var scrollView: LoginScrollView!

    @IBOutlet weak private var passwordLabel: UILabel!
    @IBOutlet weak private var passwordTextField: UITextField!

    @IBOutlet weak private var okButton: UIButton!
    @IBOutlet weak private var cancelButton: UIButton!

    @IBOutlet weak private var scrollViewBottomConstraint: NSLayoutConstraint!

    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

// MARK: - ViewModel

    public var viewModel: ClientCertificatePasswordViewModel?

// MARK: - Localized strings

    private struct Localized {
        static let title = NSLocalizedString("Client Certificate",
                                             comment: "Header for client certificate password screen")
        static let message = NSLocalizedString("Please enter the password of the certificate to import it:",
                                               comment: "Description for client certificate password screen")
        static let ok = NSLocalizedString("OK",
                                          comment: "Cancel button for client certificate password screen")
        static let cancel = NSLocalizedString("Cancel",
                                              comment: "Cancel button for client certificate password screen")
    }

// MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // I want to check that viewModel was initiated (only once)
        guard let _ = viewModel else {
            Log.shared.errorAndCrash("Lost viewModel")
            return
        }

        passwordTextField.delegate = self
        scrollView.loginScrollViewDelegate = self
        setupConstraints()
        setupStyle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateConstraints()
    }

    /// Setup constraints arrays for cancel & OK buttons.
    private func setupConstraints() {
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.translatesAutoresizingMaskIntoConstraints = false

        portraitConstraints = [cancelButton.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
                               cancelButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 12),
                               okButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),
                               okButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 12)
        ]

        landscapeConstraints = [cancelButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
                               cancelButton.rightAnchor.constraint(equalTo: passwordTextField.leftAnchor, constant: -26),
                               okButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
                               okButton.leftAnchor.constraint(equalTo: passwordTextField.rightAnchor, constant: 26)]
    }

    /// Change constraints for cancel & OK buttons between portrait and landscape modes
    private func updateConstraints() {
        if UIDevice.current.orientation.isPortrait {
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        } else {
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateConstraints()
    }
}

// MARK: - Private

extension ClientCertificatePasswordViewController {
    private func setupStyle() {
        okButton.tintColor = .white
        okButton.setTitle(Localized.ok, for: .normal)
        cancelButton.tintColor = .white
        cancelButton.setTitle(Localized.cancel, for: .normal)
    }
}

// MARK: - IBAction

extension ClientCertificatePasswordViewController {
    @IBAction func cancelAction(_ sender: Any) {
        viewModel?.handleCancelButtonPresed()
    }

    @IBAction func okAction(_ sender: Any) {
        let password = passwordTextField.text ?? ""
        viewModel?.handleOkButtonPressed(password: password)
    }
}

// MARK: - ClientCertificatePasswordViewModelDelegate

extension ClientCertificatePasswordViewController: ClientCertificatePasswordViewModelDelegate {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - LoginScrollViewDelegate

extension ClientCertificatePasswordViewController: LoginScrollViewDelegate {
    var bottomConstraint: NSLayoutConstraint {
        get { scrollViewBottomConstraint }
    }
    var firstResponder: UIView? {
        get { passwordTextField }
    }
}

// MARK: - TextFieldDelegate

extension ClientCertificatePasswordViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        okAction(textField)
        return true
    }
}
