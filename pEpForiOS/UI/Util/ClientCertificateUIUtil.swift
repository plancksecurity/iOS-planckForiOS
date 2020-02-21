//
//  ClientCertificateUIUtil.swift
//  pEp
//
//  Created by Andreas Buff on 20.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - Constants

extension ClientCertificateUIUtil {
    static public let pEpClientCertificateExtension = "pEp12"
}

/// Utils for importing Client Certificates.
class ClientCertificateUIUtil: NSObject {
    private let clientCertificateUtil: ClientCertificateUtilProtocol
    private var viewControllerToPresentUiOn: UIViewController?
    private var p12Data: Data?

    public init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
    }

    public func importClientCertificate(at url: URL,
                                        viewControllerToPresentUiOn vc: UIViewController) {
        viewControllerToPresentUiOn = vc
        do {
            p12Data = try Data(contentsOf: url)
        } catch {
            showCorruptedFileError()
            return
        }
        presentAlertViewForClientImportPassPhrase()
    }
}

// MARK: - Private

extension ClientCertificateUIUtil {

    private func presentAlertViewForClientImportPassPhrase() {
        let title = NSLocalizedString("Certificate Password",
                                      comment: "Enter client certificate alert title")
        let message = NSLocalizedString("Enter password of Certificate to import it.",
                                        comment: "Enter client certificate alert message")
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addTextField { (inputTextField: UITextField) in
            inputTextField.isSecureTextEntry = true
            inputTextField.delegate = self
        }
        alert.addAction(UIAlertAction(title: "Canel", style: .cancel))
        guard let vc = viewControllerToPresentUiOn else {
            Log.shared.errorAndCrash("No VC!")
            return
        }
        vc.present(alert, animated: true)
    }

    private func handlePassphraseEntered(pass: String) {
        guard let data = p12Data else {
            Log.shared.errorAndCrash("Invalid state: Password field should never been shown before having p12Data.")
            return
        }
        do {
            try clientCertificateUtil.storeCertificate(p12Data: data, password: pass)
        } catch ClientCertificateUtil.ImportError.wrongPassword {
            showWrongPasswordError()
        } catch {
            showCorruptedFileError()
        }
    }

    private func showCorruptedFileError() {
        guard let vc = viewControllerToPresentUiOn else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        let title = NSLocalizedString("Corrupted File",
                                      comment: "Client certificate import: corrupted file error alert title")
        let message = NSLocalizedString("The file could not be imported",
                                      comment: "Client certificate import: corrupted file error alert message")
        UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                message: message,
                                                inViewController: vc)
    }

    private func showWrongPasswordError() {
        guard let vc = viewControllerToPresentUiOn else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        let title = NSLocalizedString("Wrong Password",
                                      comment: "Client certificate import: wrong password alert title")
        let message = NSLocalizedString("We could not import the certificate. The password is incorrect.\n\nTry again?",
                                        comment: "Client certificate import: wrong password alert message")
        UIUtils.showTwoButtonAlert(withTitle: title, message: message, cancelButtonText: "No", positiveButtonText: "Yes", cancelButtonAction: {
            // Do nothing
        }, positiveButtonAction: { [weak self] in
            // Show password input again
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.presentAlertViewForClientImportPassPhrase()
        }, inViewController: vc)
    }
}

// MARK: - UITextFieldDelegate

extension ClientCertificateUIUtil: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        handlePassphraseEntered(pass: textField.text ?? "")
    }
}
