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

// MARK: - Localized strings

private struct Localized {
    struct WrongPasswordError {
        static let title = NSLocalizedString("Wrong Password",
                                             comment: "Client certificate import: wrong password alert title")
        static let message = NSLocalizedString("We could not import the certificate. The password is incorrect.\n\nTry again?",
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
}

/// Utils for importing Client Certificates.
final class ClientCertificateUIUtil: NSObject {
    private let clientCertificateUtil: ClientCertificateUtilProtocol
    private var viewControllerToPresentUiOn: UIViewController?
    private var clientCertificatePasswordVC: ClientCertificatePasswordViewController? {
        let vc = UIStoryboard.init(name: "Certificates",
                          bundle: nil).instantiateInitialViewController() as? ClientCertificatePasswordViewController
        vc?.viewModel = ClientCertificatePasswordViewModel(delegate: vc,
                                                           passwordChangeDelegate: self)
        return vc
    }
    private var p12Data: Data?

    public init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
    }

    typealias Success = Bool
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

        guard let viewControllerPresenter = viewControllerToPresentUiOn else {
            Log.shared.errorAndCrash("No VC!")
            return
        }

        guard let clientCertificatePasswordVC = clientCertificatePasswordVC else {
            Log.shared.errorAndCrash("Certificates storyboard not found")
            return
        }
        clientCertificatePasswordVC.modalPresentationStyle = .fullScreen
        viewControllerPresenter.present(clientCertificatePasswordVC, animated: true)
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
        guard let vc = topViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        UIUtils.showAlertWithOnlyPositiveButton(title: Localized.CorruptedFileError.title,
                                                message: Localized.CorruptedFileError.message,
                                                inViewController: vc, completion: { [weak self] in
                                                    guard let me = self else {
                                                        Log.shared.lostMySelf()
                                                        return
                                                    }
                                                    me.dismissView()
        })
    }

    private func showWrongPasswordError() {
        guard let vc = topViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        UIUtils.showTwoButtonAlert(withTitle: Localized.WrongPasswordError.title,
                                   message: Localized.WrongPasswordError.message,
                                   cancelButtonText: Localized.no,
                                   positiveButtonText: Localized.yes,
                                   cancelButtonAction: { [weak self] in
                                    guard let me = self else {
                                        Log.shared.lostMySelf()
                                        return
                                    }
                                    me.dismissView()
            }, positiveButtonAction: {
                // We don't need to do something here. Our expectation is close this alert
        }, inViewController: vc)
    }

    private func dismissView() {
        guard let viewClientCertificatePasswordVC = clientCertificatePasswordVC else {
            Log.shared.errorAndCrash("No viewControllerToPresent!")
            return
        }
        viewClientCertificatePasswordVC.dismiss(animated: true)
    }
}

// MARK: - ClientCertificatePasswordDelegate

extension ClientCertificateUIUtil: ClientCertificatePasswordViewModelPasswordChangeDelegate {
    func didEnter(password: String) {
        handlePassphraseEntered(pass: password)
    }
}
