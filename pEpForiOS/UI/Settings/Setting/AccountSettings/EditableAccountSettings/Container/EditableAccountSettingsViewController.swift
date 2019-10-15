//
//  EditableAccountSettingsViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class EditableAccountSettingsViewController: BaseViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!

    var viewModel: EditableAccountSettingsViewModel? = nil

//    let oauthViewModel = OAuth2AuthViewModel()

    override func viewDidLoad() {
        viewModel?.verifiableDelegate = self
        viewModel?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationController?.setToolbarHidden(true, animated: false)

        guard let isIphone = splitViewController?.isCollapsed else {
            return
        }
        if !isIphone {
            self.navigationItem.leftBarButtonItem = nil// hidesBackButton = true
        }
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        guard let isSplitViewShown = splitViewController?.isCollapsed else {
            return
        }
        if isSplitViewShown {
            popViewController()
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
//        do {
//            let validated = try validateInput()
//
//            let imap = AccountSettingsViewModel.ServerViewModel(address: validated.addrImap,
//                                                                port: validated.portImap,
//                                                                transport: validated.transImap)
//
//            let smtp = AccountSettingsViewModel.ServerViewModel(address: validated.addrSmpt,
//                                                                port: validated.portSmtp,
//                                                                transport: validated.transSmtp)
//
//            var password: String? = passwordTextfield.text
//            if passWordChanged == false {
//                password = nil
//            }
//
//            setLoadingOverlayView(hidden: false, animated: true)
//            viewModel?.update(loginName: validated.loginName, name: validated.accountName,
//                              password: password, imap: imap, smtp: smtp)
//        } catch {
//            informUser(about: error)
//        }
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
