//
//  AccountTypeSelectorViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox
import MessageModel

final class AccountTypeSelectorViewController: UIViewController {

    var viewModel = AccountTypeSelectorViewModel()
    weak var delegate: AccountTypeSelectorViewModelDelegate?
    weak var loginDelegate: LoginViewControllerDelegate?

    @IBOutlet private weak var selectAccountTypeLabel: UILabel!
    @IBOutlet private weak var welcomeToPepLabel: UILabel!
    @IBOutlet weak var clientCertificateButton: AccountSelectorButton!
    
    private var attrs = [
        NSAttributedString.Key.font : UIFont.pepFont(style: .callout, weight: .regular),
        NSAttributedString.Key.foregroundColor : UITraitCollection.current.userInterfaceStyle == .light ? UIColor.secondary : .white,
        NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]

    private var highlightedAttrs = [
        NSAttributedString.Key.font : UIFont.pepFont(style: .callout, weight: .regular),
        NSAttributedString.Key.foregroundColor : UIColor.selected,
        NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]

    var attributedString = NSMutableAttributedString(string:"")

    @IBOutlet weak var termsAndConditionsButton: UIButton!
    
    private var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        let termsAndConditions = NSLocalizedString("Terms and conditions", comment: "Terms and conditions - title")
        let buttonTitleStr = NSMutableAttributedString(string:termsAndConditions, attributes:attrs)
        let highlightedButtonTitleStr = NSMutableAttributedString(string:termsAndConditions, attributes:highlightedAttrs)

        attributedString.append(buttonTitleStr)
        termsAndConditionsButton.setAttributedTitle(attributedString, for: .normal)
        termsAndConditionsButton.setAttributedTitle(highlightedButtonTitleStr, for: .highlighted)
    }

    @IBAction func termsAndConditionsButtonPressed() {
        guard let myUrl = InfoPlist.termsAndConditionsURL(),
                let url = URL(string: "\(myUrl)") else {
            Log.shared.errorAndCrash("URL corrupted")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func microsoftButtonPressed() {
        isCurrentlyVerifying = true
        viewModel.handleDidSelect(accountType: .microsoft, viewController : self)
    }

    @IBAction func googleButtonPressed() {
        isCurrentlyVerifying = true
        viewModel.handleDidSelect(accountType: .google, viewController : self)
    }

    @IBAction func passwordButtonPressed() {
        viewModel.handleDidSelect(accountType: .other)
        performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAppearance()
        configureView()
        updateView()
        clientCertificateButton.isHidden = !viewModel.shouldShowClientCertificateButton()
    }

    @objc func backButton() {
        dismiss(animated: true)
    }
}
// MARK: - Private

extension AccountTypeSelectorViewController {
    private func updateView() {
        if isCurrentlyVerifying {
            LoadingInterface.showLoadingInterface()
        } else {
            LoadingInterface.removeLoadingInterface()
        }
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

    private func handleLoginError(error: Error) {
        Log.shared.log(error: error)
        isCurrentlyVerifying = false

        var title = NSLocalizedString("Invalid Address",
                                      comment: "Please enter a valid Gmail address.Fail to log in, email does not match account type")

        var message: String?

        switch viewModel.loginUtil.verifiableAccount.accountType {
        case .gmail:
            message = NSLocalizedString("Please enter a valid Gmail address.",
                                        comment: "Fail to log in, email does not match account type")
        case .o365:
            message = NSLocalizedString("Please enter a valid Microsoft address.",
                                        comment: "Fail to log in, email does not match account type")
        default:
            Log.shared.errorAndCrash("Login should not do oauth with other email address")
        }
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message) { [weak self] in
            guard self != nil else {
                Log.shared.lostMySelf()
                return
            }
        }
    }
}

// MARK: - AccountTypeSelectorViewModelDelegate

extension AccountTypeSelectorViewController: AccountTypeSelectorViewModelDelegate {
    func didVerify(result: AccountVerificationResult) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            switch result {
            case .ok:
                me.isCurrentlyVerifying = false
                me.loginDelegate?.loginViewControllerDidCreateNewAccount(LoginViewController())
                me.navigationController?.dismiss(animated: true)
            case .imapError(let err):
                me.handleLoginError(error: err)
            case .smtpError(let err):
                me.handleLoginError(error: err)
            case .noImapConnectData, .noSmtpConnectData:
                me.handleLoginError(error: LoginViewController.LoginError.noConnectData)
            }
        }
    }

    func handle(oauth2Error: Error) {
        handleLoginError(error: oauth2Error)
    }

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
