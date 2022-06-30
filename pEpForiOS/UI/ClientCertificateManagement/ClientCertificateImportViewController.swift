//
//  ClientCertificateImportViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

// MARK: - Constants

extension ClientCertificateImportViewController {
    static public let pEpClientCertificateExtension = "pEp12"
    static public let storyboadIdentifier = "ClientCertificatePasswordViewController"
}

protocol ClientCertificateImportViewControllerDelegate: AnyObject {
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

// MARK: - ViewModel

    public var viewModel: ClientCertificateImportViewModel?
    
    weak var delegate: ClientCertificateImportViewControllerDelegate?

// MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTextField.delegate = self
        scrollView.dynamicHeightScrollViewDelegate = self
        setupStyle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.importClientCertificate()
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.ClientCertificateImportView,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewDidAppear, withEventProperties:attributes)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.ClientCertificateImportView,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewDidDisappear, withEventProperties:attributes)
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
        case .invalidFileType:
            showInvalidFileTypeError()
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
    private func showCorruptedFileError() {
        let title = Localized.CorruptedFileError.title
        let message = Localized.CorruptedFileError.message
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dismiss(animated: true) {
                me.dismiss(animated: true)
            }
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
                                    //Dismisses the error view regardless of whether the view was presented modally or pushed
                                    me.dismissAndPerform {
                                        me.dismiss()
                                    }
                                   }, positiveButtonAction: {
                                    // We don't need to do something here. Our expectation is close this alert
                                   })
    }

    private func showInvalidFileTypeError() {
        let title = Localized.InvalidFileTypeError.title
        let message = Localized.InvalidFileTypeError.message
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dismiss(animated: true) {
                me.dismiss(animated: true)
            }
        }
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

    struct InvalidFileTypeError {
        static let title = NSLocalizedString("Invalid Certificate",
                                             comment: "Client certificate import: File does not look like a certificate title")
        static let message = NSLocalizedString("The file could not be imported as a certificate",
                                               comment: "Client certificate import: File does not look like a certificate")
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
