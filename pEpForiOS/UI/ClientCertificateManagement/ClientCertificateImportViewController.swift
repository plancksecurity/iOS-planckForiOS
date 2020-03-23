//
//  ClientCertificateImportViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

// MARK: - Constants

extension ClientCertificateImportViewController {
    static public let pEpClientCertificateExtension = "pEp12"
    static public let storyboadIdentifier = "ClientCertificatePasswordViewController"
}

protocol ClientCertificateImportViewControllerDelegate: class {
    func certificateCouldImported()
}

final class ClientCertificateImportViewController: UIViewController {

// MARK: - IBOutlet
    
    @IBOutlet weak private var scrollView: DynamicHeightScrollView!

    @IBOutlet weak private var passwordLabel: UILabel!
    @IBOutlet weak private var passwordTextField: UITextField!
    @IBOutlet weak private var okButton: UIButton!
    @IBOutlet weak private var cancelButton: UIButton!

    @IBOutlet weak private var scrollViewBottomConstraint: NSLayoutConstraint!

    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

// MARK: - ViewModel

    public var viewModel: ClientCertificateImportViewModel?
    
    weak var delegate: ClientCertificateImportViewControllerDelegate?

// MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTextField.delegate = self
        scrollView.dynamicHeightScrollViewDelegate = self
        setupConstraints()
        setupStyle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateConstraints()
        viewModel?.importClientCertificate()
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

extension ClientCertificateImportViewController {
    private func setupStyle() {
        okButton.tintColor = .white
        okButton.setTitle(Localized.ok, for: .normal)
        cancelButton.tintColor = .white
        cancelButton.setTitle(Localized.cancel, for: .normal)
    }
}

// MARK: - IBAction

extension ClientCertificateImportViewController {
    @IBAction func cancelAction(_ sender: Any) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Lost viewModel")
            return
        }
        vm.handleCancelButtonPresed()
    }

    @IBAction func okAction(_ sender: Any) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Lost viewModel")
            return
        }
        let password = passwordTextField.text ?? ""
        vm.handlePassphraseEntered(pass: password)
    }
}

// MARK: - ClientCertificatePasswordViewModelDelegate

extension ClientCertificateImportViewController: ClientCertificateImportViewModelDelegate {
    func showError(type: ImportCertificateError, dissmisAfterError: Bool) {
        switch type {
        case .wrongPassword:
            showWrongPasswordError()
        case .corruptedFile:
            showCorruptedFileError()
        case .noPermissions:
            showPermissionsDeniedError()
        }
    }
    
    func dismiss() {
        delegate?.certificateCouldImported()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - DynamicHeightScrollViewDelegate

extension ClientCertificateImportViewController: DynamicHeightScrollViewDelegate {
    var bottomConstraint: NSLayoutConstraint {
        get { scrollViewBottomConstraint }
    }
    var firstResponder: UIView? {
        get { passwordTextField }
    }
}

// MARK: - TextFieldDelegate

extension ClientCertificateImportViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        okAction(textField)
        return true
    }
}

// MARK: - Showing Error

extension ClientCertificateImportViewController {

    private func showPermissionsDeniedError() {
        UIUtils.showAlertWithOnlyPositiveButton(title: Localized.PermissionsDeniedError.title,
                                                message: Localized.PermissionsDeniedError.message,
                                                inNavigationStackOf: self) { [weak self] in
                                                    guard let me = self else {
                                                        Log.shared.lostMySelf()
                                                        return
                                                    }
                                                    me.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showCorruptedFileError() {
        UIUtils.showAlertWithOnlyPositiveButton(title: Localized.CorruptedFileError.title,
                                                message: Localized.CorruptedFileError.message,
                                                inNavigationStackOf: self) { [weak self] in
                                                    guard let me = self else {
                                                        Log.shared.lostMySelf()
                                                        return
                                                    }
                                                    me.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showWrongPasswordError() {
        UIUtils.showTwoButtonAlert(withTitle: Localized.WrongPasswordError.title,
                                   message: Localized.WrongPasswordError.message,
                                       cancelButtonText: Localized.no,
                                       positiveButtonText: Localized.yes,
                                       cancelButtonAction: { [weak self] in
                                        guard let me = self else {
                                            Log.shared.lostMySelf()
                                            return
                                        }
                                        me.dismiss(animated: true, completion: nil)
            }, positiveButtonAction: {
                // We don't need to do something here. Our expectation is close this alert
        }, inNavigationStackOf: self)
    }
}

// MARK: - Localized strings

private struct Localized {
    struct WrongPasswordError {
        static let title = NSLocalizedString("Wrong Password",
                                             comment: "Client certificate import: wrong password alert title")
        static let message = NSLocalizedString("We could not import the certificate. The password is incorrect.\n\nTry again?",
                                               comment: "Client certificate import: wrong password alert message")
    }
    struct PermissionsDeniedError {
        static let title = NSLocalizedString("Permissions Denied",
                                             comment: "Client certificate import: PermissionsDenied alert title")
        static let message = NSLocalizedString("We could not import the certificate. We do not have permissions to open this file.\n\nTry again?",
                                               comment: "Client certificate import: wrong password alert message")
    }
    struct CorruptedFileError {
        static let title = NSLocalizedString("Corrupted File",
                                             comment: "Client certificate import: corrupted file error alert title")
        static let message = NSLocalizedString("The file could not be imported",
                                               comment: "Client certificate import: corrupted file error alert message")
    }
    static let no = NSLocalizedString("No",
                                      comment: "Alert button while client certificate is importing: Try again? No")
    static let yes = NSLocalizedString("Yes",
                                       comment: "Alert button while client certificate is importing: Try again? Yes")
    static let title = NSLocalizedString("Client Certificate",
                                         comment: "Header for client certificate password screen")
    static let message = NSLocalizedString("Please enter the password of the certificate to import it:",
                                           comment: "Description for client certificate password screen")
    static let ok = NSLocalizedString("OK",
                                      comment: "OK button for client certificate password screen")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Cancel button for client certificate password screen")
}


