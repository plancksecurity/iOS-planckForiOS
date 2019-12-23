//
//  AccountSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 12/22/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import pEpIOSToolbox

final class AccountSettingsTableViewController: BaseTableViewController {
    //general account fields
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var resetIdentityLabel: UILabel!
    //imap fields
    @IBOutlet weak var imapServerTextfield: UITextField!
    @IBOutlet weak var imapPortTextfield: UITextField!
    @IBOutlet weak var imapSecurityTextfield: UITextField!
    @IBOutlet weak var imapUsernameTextField: UITextField!
    //smtp account fields
    @IBOutlet weak var smtpServerTextfield: UITextField!
    @IBOutlet weak var smtpPortTextfield: UITextField!
    @IBOutlet weak var smtpSecurityTextfield: UITextField!
    @IBOutlet weak var smtpUsernameTextField: UITextField!

    @IBOutlet weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet weak var oauth2TableViewCell: UITableViewCell!
    @IBOutlet weak var oauth2ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pEpSyncToggle: UISwitch!
    @IBOutlet weak var resetIdentityCell: UITableViewCell!

    /**
     When dealing with an OAuth2 account, this is the index path of the cell that
     should trigger the reauthorization.
     */
    var oauth2ReauthIndexPath: IndexPath?
    var viewModel: AccountSettingsViewModel? = nil

    let oauthViewModel = OAuth2AuthViewModel()

    private var resetIdentityIndexPath: IndexPath?

     override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationController?.setToolbarHidden(true, animated: false)
        hideBackButtonIfNeeded()
        //Work around async old stack context merge behaviour
        DispatchQueue.main.async { [weak self] in
            self?.setUpView()
        }
    }

    @IBAction func didPressPEPSyncToggle(_ sender: UISwitch) {
        viewModel?.pEpSync(enable: sender.isOn)
    }
}

// MARK: - UITableViewDataSource

extension AccountSettingsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.count ?? 0
    }
    
    override func tableView(
        _ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel?[section]
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel?.footerFor(section: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let origCount = super.tableView(tableView, numberOfRowsInSection: section)
        if section == 0 {
            return origCount - 1
        } else {
            return origCount
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if (viewModel?.isOAuth2 ?? false) && cell == passwordTableViewCell {
            oauth2ReauthIndexPath = indexPath
            return oauth2TableViewCell
        }

        if cell == resetIdentityCell {
            resetIdentityIndexPath = indexPath
        }

        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let editableAccountSettingsViewController as EditableAccountSettingsViewController:
            editableAccountSettingsViewController.appConfig = appConfig
            if let account = viewModel?.account {
                editableAccountSettingsViewController.viewModel =
                    EditableAccountSettingsViewModel(account: account)
            }
        default:
            break
        }
    }
}

// MARK: - UITextFieldDelegate

extension AccountSettingsTableViewController: UITextFieldDelegate {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case oauth2ReauthIndexPath:
            handleOauth2Reauth()
        case resetIdentityIndexPath:
            handleResetIdentity()
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - AccountSettingsViewModelDelegate

extension AccountSettingsTableViewController: AccountSettingsViewModelDelegate {
    func undoPEPSyncToggle() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.pEpSyncToggle.setOn(!me.pEpSyncToggle.isOn, animated: true)
        }
    }

    func showErrorAlert(error: Error) {
        Log.shared.error("%@", "\(error)")
        UIUtils.show(error: error, inViewController: self)
    }

    func showLoadingView() {
        DispatchQueue.main.async {
            LoadingInterface.showLoadingInterface()
        }
    }

    func hideLoadingView() {
        DispatchQueue.main.async {
            LoadingInterface.removeLoadingInterface()
        }
    }
}

// MARK: - OAuth2AuthViewModelDelegate

extension AccountSettingsTableViewController: OAuth2AuthViewModelDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        oauth2ActivityIndicator.stopAnimating()
        shouldHandleErrors = true

        if let error = oauth2Error {
            showErrorAlert(error: error)
            return
        }
        guard let token = accessToken else {
            showErrorAlert(error: OAuth2AuthViewModelError.noToken)
            return
        }
        viewModel?.updateToken(accessToken: token)
    }
}

// MARK: - Private

extension AccountSettingsTableViewController {
    private func setUpView() {
        nameTextfield.text = viewModel?.account.user.userName
        emailTextfield.text = viewModel?.account.user.address
        passwordTextfield.text = "JustAPassword"
        resetIdentityLabel.text = NSLocalizedString("Reset This Identity", comment: "Account settings reset this identity")
        resetIdentityLabel.textColor = .pEpRed

        if let viewModel = viewModel {
            pEpSyncToggle.isOn = viewModel.pEpSync
        }

        if let imapServer = viewModel?.account.imapServer {
            imapServerTextfield.text = imapServer.address
            imapPortTextfield.text = String(imapServer.port)
            imapSecurityTextfield.text = imapServer.transport.asString()
            imapUsernameTextField.text = imapServer.address //this should be the username
            //viewModel?.account.imapServer?.credentials.loginName
        }

        if let smtpServer = viewModel?.account.smtpServer {
            self.smtpServerTextfield.text = smtpServer.address
            self.smtpPortTextfield.text = String(smtpServer.port)
            smtpSecurityTextfield.text = smtpServer.transport.asString()
            smtpUsernameTextField.text = smtpServer.address //this should be the username
        }
    }

    private func informUser(about error:Error) {
        let alert = UIAlertController.pEpAlertController(
            title: NSLocalizedString(
                "Invalid Input",
                comment: "Title of invalid accout settings user input alert"),
            message: error.localizedDescription,
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString(
                "OK",
                comment: "OK button for invalid accout settings user input alert"),
            style: .cancel, handler: nil)

        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func popViewController() {
        //!!!: see IOS-1608 this is a patch as we have 2 navigationControllers and need to pop to the previous view.
        (navigationController?.parent as? UINavigationController)?.popViewController(animated: true)
    }

    private func handleOauth2Reauth() {
        guard let address = viewModel?.account.user.address else {
            return
        }
        oauth2ActivityIndicator.startAnimating()

        // don't accept errors form other places
        shouldHandleErrors = false

        oauthViewModel.delegate = self
        oauthViewModel.authorize(
            authorizer: appConfig.oauth2AuthorizationFactory.createOAuth2Authorizer(),
            emailAddress: address,
            viewController: self)
    }

    private func handleResetIdentity() {
        let title = NSLocalizedString("Reset", comment: "Account settings confirm to reset identity title alert")
        let message = NSLocalizedString("This action will reset your identity. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")

        guard let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: title,
                                                  message: message,
                                                  paintPEPInTitle: true) else {
                                                    Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
                                                    return
        }

        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let cancelAction = PEPUIAlertAction(title: cancelTitle,
                                            style: .pEpGray,
                                            handler: { _ in
                                                pepAlertViewController.dismiss(animated: true,
                                                                               completion: nil)
        })
        pepAlertViewController.add(action: cancelAction)

        let resetTitle = NSLocalizedString("Reset", comment: "Reset account identity button title")
        let resetAction = PEPUIAlertAction(title: resetTitle,
                                           style: .pEpRed,
                                           handler: { [weak self] _ in
                                            pepAlertViewController.dismiss(animated: true,
                                                                           completion: nil)
                                            guard let me = self else {
                                                Log.shared.lostMySelf()
                                                return
                                            }
                                            me.viewModel?.handleResetIdentity()
        })
        pepAlertViewController.add(action: resetAction)

        pepAlertViewController.modalPresentationStyle = .overFullScreen
        pepAlertViewController.modalTransitionStyle = .crossDissolve

        DispatchQueue.main.async { [weak self] in
            self?.present(pepAlertViewController, animated: true)
        }
    }

    private func hideBackButtonIfNeeded() {
        if !onlySplitViewMasterIsShown {
            navigationItem.leftBarButtonItem = nil// hidesBackButton = true
        }
    }
}
