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
    @IBOutlet weak var keySyncLabel: UILabel!
    @IBOutlet weak var keySyncSwitch: UISwitch!
    @IBOutlet weak var certificateLabel: UITextField!
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

    @IBOutlet weak var certificateTableViewCell: UITableViewCell!
    @IBOutlet weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet weak var oauth2TableViewCell: UITableViewCell!
    @IBOutlet weak var oauth2ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resetIdentityCell: UITableViewCell!
    @IBOutlet weak var switchKeySyncCell: UITableViewCell!

    let oauthViewModel = OAuthAuthorizer()
    /**
     When dealing with an OAuth2 account, this is the index path of the cell that
     should trigger the reauthorization.
     */
    var oauth2ReauthIndexPath: IndexPath?
    var viewModel: AccountSettingsViewModel? = nil

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }
    
    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }
    private var resetIdentityIndexPath: IndexPath?
    private var certificateIndexPath: IndexPath?


    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(PEPHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        viewModel?.delegate = self

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
        title = NSLocalizedString("Account", comment: "Account view title")
        navigationController?.navigationController?.setToolbarHidden(true, animated: false)
        //Work around async old stack context merge behaviour
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.setUpView()
        }
    }

    // MARK: - IBActions

    @IBAction func switchPEPSyncToggle(_ sender: UISwitch) {
        viewModel?.pEpSync(enable: sender.isOn)
    }
}

// MARK: - UITableViewDataSource

extension AccountSettingsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }

        headerView.title = viewModel?[section].uppercased() ?? ""
        return headerView
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
        if cell == switchKeySyncCell {
            setUpKeySyncCell(cell: cell)
        }

        if (viewModel?.isOAuth2 ?? false) && cell == passwordTableViewCell {
            oauth2ReauthIndexPath = indexPath
            return oauth2TableViewCell
        }
        if cell == certificateTableViewCell {
            certificateIndexPath = indexPath
        }
        
        if cell == resetIdentityCell {
            resetIdentityIndexPath = indexPath
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let defaultValue = super.tableView(tableView, heightForRowAt: indexPath)
        guard let vm = viewModel else {
            return defaultValue
        }
        if vm.rowShouldBeHidden(indexPath: indexPath) {
            return 0
        } else {
            return defaultValue
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
        case certificateIndexPath:
            handleCertificate()
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
            me.keySyncSwitch.setOn(!me.keySyncSwitch.isOn, animated: true)
        }
    }

    func showErrorAlert(error: Error) {
        Log.shared.error("%@", "\(error)")
        UIUtils.show(error: error)
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

// MARK: - OAuthAuthorizerDelegate

extension AccountSettingsTableViewController: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        oauth2ActivityIndicator.stopAnimating()
        shouldHandleErrors = true

        if let error = oauth2Error {
            showErrorAlert(error: error)
            return
        }
        guard let token = accessToken else {
            showErrorAlert(error: OAuthAuthorizerError.noToken)
            return
        }
        viewModel?.updateToken(accessToken: token)
    }
}

// MARK: - Private

extension AccountSettingsTableViewController {

    private struct Localized {
        static let navigationTitle = NSLocalizedString("Account",
                                                       comment: "Account settings")
    }

    private func setUpView() {
        title = Localized.navigationTitle
        nameTextfield.text = viewModel?.account.user.userName
        emailTextfield.text = viewModel?.account.user.address
        certificateLabel.text = viewModel?.certificateInfo()
        passwordTextfield.text = "JustAPassword"
        resetIdentityLabel.text = NSLocalizedString("Reset",
                                                    comment: "Account settings reset identity")
        resetIdentityLabel.textColor = .pEpRed

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            keySyncSwitch.isOn = false
            return
        }

        vm.isPEPSyncEnabled { [weak self] (isOn) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.keySyncSwitch.isOn = isOn
        }

        guard let imapServer = vm.account.imapServer else {
            Log.shared.errorAndCrash("Account without IMAP server")
            return
        }
        imapServerTextfield.text = imapServer.address
        imapPortTextfield.text = String(imapServer.port)
        imapSecurityTextfield.text = imapServer.transport.asString()
        imapUsernameTextField.text = imapServer.credentials.loginName

        guard let smtpServer = vm.account.smtpServer else {
            Log.shared.errorAndCrash("Account without SMTP server")
            return
        }
        smtpServerTextfield.text = smtpServer.address
        smtpPortTextfield.text = String(smtpServer.port)
        smtpSecurityTextfield.text = smtpServer.transport.asString()
        smtpUsernameTextField.text = smtpServer.credentials.loginName
    }

    private func informUser(about error: Error) {
        let title = NSLocalizedString("Invalid Input", comment: "Title of invalid accout settings user input alert")
        let message = error.localizedDescription
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message)
    }

    private func popViewController() {
        //!!!: see IOS-1608 this is a patch as we have 2 navigationControllers and need to pop to the previous view.
        (navigationController?.parent as? UINavigationController)?.popViewController(animated: true)
    }
    
    private func handleCertificate() {
        guard let vc = UIStoryboard.init(name: "AccountCreation", bundle: nil).instantiateViewController(withIdentifier: "ClientCertificateManagementViewController") as? ClientCertificateManagementViewController else {
            return
        }
        vc.appConfig = appConfig
        let nextViewModel = viewModel?.clientCertificateViewModel()
        nextViewModel?.delegate = vc
        vc.viewModel = nextViewModel
        navigationController?.pushViewController(vc, animated: true)
    }

    private func handleOauth2Reauth() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(message: "A view model is required")
            return
        }

        guard let accountType = vm.account.accountType else {
            Log.shared.errorAndCrash(message: "Handling OAuth2 reauth requires an account with a known account type for determining the OAuth2 configuration")
            return
        }

        oauth2ActivityIndicator.startAnimating()

        // don't accept errors form other places
        shouldHandleErrors = false

        oauthViewModel.delegate = self
        oauthViewModel.authorize(
            authorizer: appConfig.oauth2AuthorizationFactory.createOAuth2Authorizer(),
            emailAddress: vm.account.user.address,
            accountType: accountType,
            viewController: self)
    }

    private func handleResetIdentity() {
        let title = NSLocalizedString("Reset", comment: "Account settings confirm to reset identity title alert")
        let message = NSLocalizedString("This action will reset your identity. \n Are you sure you want to reset?", comment: "Account settings confirm to reset identity title alert")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let resetTitle = NSLocalizedString("Reset", comment: "Reset account identity button title")
        UIUtils.showTwoButtonAlert(withTitle: title, message: message, cancelButtonText: cancelTitle, positiveButtonText: resetTitle, cancelButtonAction: { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dismiss(animated: true)
        }, positiveButtonAction: { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dismiss(animated: true)
            me.viewModel?.handleResetIdentity()
        },
        style: PEPAlertViewController.AlertStyle.warn)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let editableAccountSettingsViewController as EditableAccountSettingsViewController:
            guard let account = viewModel?.account else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            editableAccountSettingsViewController.appConfig = appConfig
            editableAccountSettingsViewController.viewModel = EditableAccountSettingsViewModel(account: account)
        default:
            break
        }
    }

    /// Set up key sync cell
    /// - Parameters:
    ///   - cell: UITableViewCell
    ///   - isOn: keySyncSwitch status
    ///   - isGreyedOut: keySyncSwitch (if true - user can't interact with this cell)
    private func setUpKeySyncCell(cell: UITableViewCell) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            keySyncSwitch.isOn = false
            return
        }
        let isGreyedOut = vm.isPEPSyncSwitchGreyedOut()
        cell.isUserInteractionEnabled = !isGreyedOut
        keySyncLabel.textColor = isGreyedOut
            ? .gray
            : .pEpTextDark

        keySyncSwitch.onTintColor = isGreyedOut
            ? .pEpGreyBackground
            : .pEpGreen
        keySyncSwitch.isEnabled = !isGreyedOut

        vm.isPEPSyncEnabled { [weak self] (isOn) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.keySyncSwitch.isOn = isOn
        }
    }
}
