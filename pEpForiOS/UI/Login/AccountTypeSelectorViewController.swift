//
//  AccountTypeSelectorViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

final class AccountTypeSelectorViewController: UIViewController {

    var viewModel = AccountTypeSelectorViewModel()
    weak var delegate: AccountTypeSelectorViewModelDelegate?
    weak var loginDelegate: LoginViewControllerDelegate?

    @IBOutlet private weak var selectAccountTypeLabel: UILabel!
    @IBOutlet private weak var welcomeToPepLabel: UILabel!
    @IBOutlet weak var clientCertificateButton: AccountSelectorButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
    }

    @IBAction func microsoftButtonPressed() {
        viewModel.handleDidSelect(accountType: .microsoft)
    }

    @IBAction func googleButtonPressed() {
        viewModel.handleDidSelect(accountType: .google)
    }

    @IBAction func passwordButtonPressed() {
        viewModel.handleDidSelect(accountType: .other)
        performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAppearance()
        configureView()
        clientCertificateButton.isHidden = !viewModel.shouldShowClientCertificateButton()
    }

    private func configureAppearance() {
        Appearance.customiseForLogin(viewController: self)
    }

    private func configureView() {
        //as we need a title for the back button of the next view
        //but this title is not show
        //the view in the title are is replaced for a blank view.
        navigationItem.titleView = UIView()
        title = NSLocalizedString("Account Select", comment: "account type selector title")
        navigationController?.navigationBar.isHidden = !viewModel.isThereAnAccount()
        let imagebutton = UIButton(type: .custom)
        let image = UIImage(named: "close-icon")

        imagebutton.setImage(image, for: .normal)
        imagebutton.addTarget(self, action: #selector(backButton), for: .touchUpInside)
        imagebutton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let finalBarButton = UIBarButtonItem(customView: imagebutton)
        navigationItem.leftBarButtonItem = finalBarButton
    }
    
    @objc func backButton() {
        dismiss(animated: true)
    }
}

extension AccountTypeSelectorViewController: AccountTypeSelectorViewModelDelegate {
    func showClientCertificateSeletionView() {
        performSegue(withIdentifier: SegueIdentifier.clientCertManagementSegue,
                     sender: self)
    }

    func showMustImportClientCertificateAlert() {
        let title = NSLocalizedString("No Client Certificate",
                                      comment: "No client certificate exists alert title")
        let message = NSLocalizedString("No client certificate exists. You have to import your client certificate before entering login data.",
                                        comment: "No client certificate exists alert message")
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.navigationController?.popViewController(animated: true)
        }
    }
}

extension AccountTypeSelectorViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case showLogin
        case clientCertManagementSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showLogin:
            guard let vc = segue.destination as? LoginViewController else {
                Log.shared.errorAndCrash("accountType is invalid")
                return
            }
            vc.viewModel = viewModel.loginViewModel()
            vc.delegate = loginDelegate
        case .clientCertManagementSegue:
            guard let dvc = segue.destination as? ClientCertificateManagementViewController else {
                Log.shared.errorAndCrash("Invalid state")
                return
            }
            dvc.viewModel = viewModel.clientCertificateManagementViewModel()
        }
    }
}

// MARK: - ClientCertificateImport Delegate

extension AccountTypeSelectorViewController: ClientCertificateImportViewControllerDelegate {

    func certificateCouldImported() {
        clientCertificateButton.isHidden = !viewModel.shouldShowClientCertificateButton()
    }
}
