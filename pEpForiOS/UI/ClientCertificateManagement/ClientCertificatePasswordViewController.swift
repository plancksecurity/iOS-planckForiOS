//
//  ClientCertificatePasswordViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class ClientCertificatePasswordViewController: BaseViewController {

// MARK: - IBOutlet

    @IBOutlet weak private var passwordLabel: UILabel!
    @IBOutlet weak private var passwordTextField: UITextField!

    @IBOutlet weak private var okButton: UIButton!
    @IBOutlet weak private var cancelButton: UIButton!

    var portraitConstraints: [NSLayoutConstraint] = []
    var landscapeConstraints: [NSLayoutConstraint] = []

// MARK: - ViewModel

    var viewModel: ClientCertificatePasswordViewModel?

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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Lost viewModel")
            return
        }


        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.translatesAutoresizingMaskIntoConstraints = false

        portraitConstraints = [cancelButton.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
                               cancelButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 0),
                               okButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),
                               okButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 0)
        ]

        landscapeConstraints = [cancelButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
                               cancelButton.rightAnchor.constraint(equalTo: passwordTextField.leftAnchor, constant: -40),
                               okButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
                               okButton.leftAnchor.constraint(equalTo: passwordTextField.rightAnchor, constant: 40)]

        setupStyle()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {

        if !UIApplication.shared.statusBarOrientation.isPortrait {
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        } else {
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
        }
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
        viewModel?.dismissImportCertificateAction()
    }

    @IBAction func okAction(_ sender: Any) {
        let password = passwordTextField.text ?? ""
        passwordTextField.text = ""
        viewModel?.importCertificateAction(password: password)
    }
}
