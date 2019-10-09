//
//  EditableAccountSettingsViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class EditableAccountSettingsViewController: UIViewController {
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var loadingOverlayView: UIView!

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        guard let isSplitViewShown = splitViewController?.isCollapsed else {
            return
        }
        if isSplitViewShown {
            popViewController()
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        do {
            let validated = try validateInput()

            let imap = AccountSettingsViewModel.ServerViewModel(address: validated.addrImap,
                                                                port: validated.portImap,
                                                                transport: validated.transImap)

            let smtp = AccountSettingsViewModel.ServerViewModel(address: validated.addrSmpt,
                                                                port: validated.portSmtp,
                                                                transport: validated.transSmtp)

            var password: String? = passwordTextfield.text
            if passWordChanged == false {
                password = nil
            }

            setLoadingOverlayView(hidden: false, animated: true)
            viewModel?.update(loginName: validated.loginName, name: validated.accountName,
                              password: password, imap: imap, smtp: smtp)
        } catch {
            informUser(about: error)
        }
    }
}

extension EditableAccountSettingsViewController {
    func setLoadingOverlayView(hidden: Bool, animated: Bool) {
        guard loadingOverlayView.isHidden != hidden else {
            return
        }
        guard animated else {
            loadingOverlayView.isHidden = hidden
            return
        }

        let finalAlpha:CGFloat = hidden ? 0 : 1
        loadingOverlayView.alpha = hidden ? 1 : 0
        loadingOverlayView.isHidden = false

        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
                        self?.loadingOverlayView.alpha = finalAlpha
            },
                       completion: { [weak self] _ in
                        self?.loadingOverlayView.isHidden = hidden
        })
    }
}

// MARK: - AccountVerificationResultDelegate

extension EditableAccountSettingsViewController: AccountVerificationResultDelegate {
    func didVerify(result: AccountVerificationResult) {
        DispatchQueue.main.async { [weak self] in
            self?.hideSpinnerAndEnableUI()
            switch result {
            case .ok:
                //self.navigationController?.popViewController(animated: true)
                self?.popViewController()
            case .imapError(let err):
                self?.handleLoginError(error: err)
            case .smtpError(let err):
                self?.handleLoginError(error: err)
            case .noImapConnectData, .noSmtpConnectData:
                self?.handleLoginError(error: LoginViewController.LoginError.noConnectData)
            }
        }
    }
}


// MARK: - Private

extension EditableAccountSettingsViewController {
    private func popViewController() {
        //!!!: see IOS-1608 this is a patch as we have 2 navigationControllers and need to pop to the previous view.
        (navigationController?.parent as? UINavigationController)?.popViewController(animated: true)
    }
}
