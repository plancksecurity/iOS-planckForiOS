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

// MARK: - IBOutlets

    @IBOutlet private var stackViews: [UIStackView]!

    //general account fields
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextfield: UITextField!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var emailTextfield: UITextField!
    @IBOutlet private weak var passwordTextfield: UITextField!
    @IBOutlet private weak var resetIdentityLabel: UILabel!
    @IBOutlet private weak var keySyncLabel: UILabel!
    @IBOutlet private weak var keySyncSwitch: UISwitch!

    //imap fields
    @IBOutlet private weak var serverLabel: UILabel!
    @IBOutlet private weak var imapServerTextfield: UITextField!
    @IBOutlet private weak var portLabel: UILabel!
    @IBOutlet private weak var imapPortTextfield: UITextField!
    @IBOutlet private weak var imapSecurityTextfield: UITextField!
    @IBOutlet private weak var imapUsernameTextField: UITextField!
    @IBOutlet private weak var imapUsernameLabel: UILabel!

    //smtp account fields
    @IBOutlet private weak var smtpServerTextfield: UITextField!
    @IBOutlet private weak var smtpPortTextfield: UITextField!
    @IBOutlet private weak var smtpSecurityTextfield: UITextField!
    @IBOutlet private weak var smtpUsernameTextField: UITextField!

    @IBOutlet private weak var certificateTableViewCell: UITableViewCell!
    @IBOutlet private weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet private weak var oauth2TableViewCell: UITableViewCell!
    @IBOutlet private weak var oauth2ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var resetIdentityCell: UITableViewCell!
    @IBOutlet private weak var switchKeySyncCell: UITableViewCell!

    @IBOutlet private weak var smtpUsernameLabel: UILabel!
    @IBOutlet private weak var smtpTransportSecurityLabel: UILabel!
    @IBOutlet private weak var smtpPortLabel: UILabel!
    @IBOutlet private weak var transportSecurityLabel: UILabel!

    @IBOutlet private weak var oAuthReauthorizationLabel: UILabel!
    @IBOutlet private weak var certificateLabel: UILabel!
    @IBOutlet private weak var certificateTextfield: UITextField!
    @IBOutlet private weak var passwordLabel: UILabel!

// MARK: - Variables
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

    @IBOutlet private weak var smtpServerLabel: UILabel!
    
    
// MARK: - Life Cycle

     override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(PEPHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        UIHelper.variableCellHeightsTableView(tableView)
        UIHelper.variableSectionFootersHeightTableView(tableView)
        UIHelper.variableSectionHeadersHeightTableView(tableView)
        viewModel?.delegate = self
        configureView(for: traitCollection)
        setFonts()
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
            setUpKeySyncCell(cell: cell,
                                   isOn: viewModel?.pEpSync ?? false,
                                   isGreyedOut: !(viewModel?.isPEPSyncSwitchGreyedOut() ?? false))
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
    private func setUpKeySyncCell(cell: UITableViewCell,
                                        isOn: Bool,
                                        isGreyedOut: Bool) {
        cell.isUserInteractionEnabled = isGreyedOut
        keySyncLabel.textColor = isGreyedOut
            ? .pEpTextDark
            : .gray
        keySyncSwitch.isOn = isOn
        keySyncSwitch.onTintColor = isGreyedOut
            ? .pEpGreen
            : .pEpGreyBackground
        keySyncSwitch.isEnabled = isGreyedOut
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
        //shouldHandleErrors = true
        //!!!: this comment should be temporal

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
        certificateTextfield.text = viewModel?.certificateInfo()
        passwordTextfield.text = "JustAPassword"
        resetIdentityLabel.text = NSLocalizedString("Reset",
                                                    comment: "Account settings reset identity")
        resetIdentityLabel.textColor = .pEpRed

        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        keySyncSwitch.isOn = viewModel.pEpSync

        guard let imapServer = viewModel.account.imapServer else {
            Log.shared.errorAndCrash("Account without IMAP server")
            return
        }
        imapServerTextfield.text = imapServer.address
        imapPortTextfield.text = String(imapServer.port)
        imapSecurityTextfield.text = imapServer.transport.asString()
        imapUsernameTextField.text = imapServer.credentials.loginName

        guard let smtpServer = viewModel.account.smtpServer else {
            Log.shared.errorAndCrash("Account without SMTP server")
            return
        }
        smtpServerTextfield.text = smtpServer.address
        smtpPortTextfield.text = String(smtpServer.port)
        smtpSecurityTextfield.text = smtpServer.transport.asString()
        smtpUsernameTextField.text = smtpServer.credentials.loginName
    }

    private func informUser(about error:Error) {
        let alert = UIAlertController.pEpAlertController(
            title: NSLocalizedString(
                "Invalid Input",
                comment: "Title of invalid accout settings user input alert"),
            message: error.localizedDescription,
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("OK",
                                     comment: "OK button for invalid accout settings user input alert"),
            style: .cancel, handler: nil)

        alert.addAction(cancelAction)
        present(alert, animated: true)
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
        //shouldHandleErrors = false
        //!!!: this comment is temporal

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

        guard let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: title,
                                                  message: message,
                                                  paintPEPInTitle: true) else {
                                                    Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
                                                    return
        }

        let cancelTitle = NSLocalizedString("Cancel",
                                            comment: "Cancel reset account identity button title")
        let cancelAction = PEPUIAlertAction(title: cancelTitle,
                                            style: .pEpGray,
                                            handler: { _ in
                                                pepAlertViewController.dismiss(animated: true,
                                                                               completion: nil)
        })
        pepAlertViewController.add(action: cancelAction)

        let resetTitle = NSLocalizedString("Reset",
                                           comment: "Reset account identity button title")
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
}

//MARK : - Accessibility

extension AccountSettingsTableViewController {

    /// To support dynamic font with a font size limit we have set the font by code.
    private func setFonts() {
        let font = UIFont.pepFont(style: .body, weight: .regular)

        //Name
        nameLabel.font = font
        nameTextfield.font = font

        //Email
        emailLabel.font = font
        emailTextfield.font = font

        //Password
        passwordLabel.font = font
        passwordTextfield.font = font

        //Certificate
        certificateLabel.font = font
        certificateTextfield.font = font

        //Key sync
        keySyncLabel.font = font

        //Reset Identity
        resetIdentityLabel.font = font

        //OAuth Reauthorization
        oAuthReauthorizationLabel.font = font

        //Server
        serverLabel.font = font
        imapServerTextfield.font = font

        //Port
        portLabel.font = font
        imapPortTextfield.font = font

        //Security
        transportSecurityLabel.font = font
        imapSecurityTextfield.font = font

        //Username
        imapUsernameLabel.font = font
        imapUsernameTextField.font = font

        //SMTP Server
        smtpServerLabel.font = font
        smtpServerTextfield.font = font

        //SMTP Server Port
        smtpPortLabel.font = font
        smtpPortTextfield.font = font

        //SMTP Server Transport Security
        smtpTransportSecurityLabel.font = font
        smtpSecurityTextfield.font = font

        //SMTP Server Username
        smtpUsernameLabel.font = font
        smtpUsernameTextField.font = font
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
        configureView(for: traitCollection)
      }
    }

    private func configureView(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        let axis : NSLayoutConstraint.Axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        let spacing : CGFloat = contentSize.isAccessibilityCategory ? 10.0 : 5.0
        stackViews.forEach {
            $0.axis = axis
            $0.spacing = spacing
        }
    }
}
