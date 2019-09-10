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

class AccountSettingsTableViewController: BaseTableViewController, UIPickerViewDelegate,
UIPickerViewDataSource, UITextFieldDelegate {
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!

    @IBOutlet weak var imapServerTextfield: UITextField!
    @IBOutlet weak var imapPortTextfield: UITextField!
    @IBOutlet weak var imapSecurityTextfield: UITextField!
    
    @IBOutlet weak var smtpServerTextfield: UITextField!
    @IBOutlet weak var smtpPortTextfield: UITextField!
    @IBOutlet weak var smtpSecurityTextfield: UITextField!
    @IBOutlet weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet weak var oauth2TableViewCell: UITableViewCell!
    @IBOutlet weak var oauth2ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var keySyncEnableSwith: UISwitch!

    private let spinner: UIActivityIndicatorView = {
        let createe = UIActivityIndicatorView()
        createe.hidesWhenStopped = true
        createe.style = .gray
        return createe
    }()

    var securityPicker: UIPickerView?

    var passWordChanged: Bool = false

    var viewModel: AccountSettingsViewModel? = nil
    let oauthViewModel = OAuth2AuthViewModel()

    var current: UITextField?

    /**
     When dealing with an OAuth2 account, this is the index path of the cell that
     should trigger the reauthorization.
     */
    var oauth2ReauthIndexPath: IndexPath?

     override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        if let vm = viewModel {
            vm.delegate = self
        }
        passwordTextfield.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let isIphone = splitViewController?.isCollapsed else {
            return
        }
        if !isIphone {
            self.navigationItem.leftBarButtonItem = nil// hidesBackButton = true
        }
    }

    private func configureView() {
        tableView.addSubview(spinner)

        self.nameTextfield.text = viewModel?.name
        self.emailTextfield.text = viewModel?.email
        self.usernameTextfield.text = viewModel?.loginName
        self.passwordTextfield.text = "JustAPassword"

        if let viewModel = viewModel {
            keySyncEnableSwith?.isOn = viewModel.is
        }

        securityPicker = UIPickerView(frame: CGRect(x: 0, y: 50, width: 100, height: 150))
        securityPicker?.delegate = self
        securityPicker?.dataSource = self
        securityPicker?.showsSelectionIndicator = true

        let imap = viewModel?.imapServer
        self.imapServerTextfield.text = imap?.address
        self.imapPortTextfield.text = imap?.port
        imapPortTextfield.delegate = self
        self.imapSecurityTextfield.text = imap?.transport
        self.imapSecurityTextfield.inputView = securityPicker
        self.imapSecurityTextfield.delegate = self
        self.imapSecurityTextfield.tag = 1

        let smtp = viewModel?.smtpServer
        self.smtpServerTextfield.text = smtp?.address
        self.smtpPortTextfield.text = smtp?.port
        smtpPortTextfield.delegate = self
        self.smtpSecurityTextfield.text = smtp?.transport
        self.smtpSecurityTextfield.inputView = securityPicker
        self.smtpSecurityTextfield.delegate = self
        self.smtpSecurityTextfield.tag = 2
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

    // MARK: - Helper
    
    private func validateInput() throws -> (addrImap: String, portImap: String, transImap: String,
        addrSmpt: String, portSmtp: String, transSmtp: String, accountName: String,
        loginName: String) {
            //IMAP
            guard let addrImap = imapServerTextfield.text, addrImap != "" else {
                let msg = NSLocalizedString("IMAP server must not be empty.",
                                            comment: "Empty IMAP server message")
                throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
            }

            guard let portImap = imapPortTextfield.text, portImap != "" else {
                let msg = NSLocalizedString("IMAP Port must not be empty.",
                                            comment: "Empty IMAP port server message")
                throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
            }

            guard let transImap = imapSecurityTextfield.text, transImap != "" else {
                let msg = NSLocalizedString("Choose IMAP transport security method.",
                                            comment: "Empty IMAP transport security method")
                throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
            }

            //SMTP
            guard let addrSmpt = smtpServerTextfield.text, addrSmpt != "" else {
                let msg = NSLocalizedString("SMTP server must not be empty.",
                                            comment: "Empty SMTP server message")
                throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
            }

            guard let portSmtp = smtpPortTextfield.text, portSmtp != "" else {
                let msg = NSLocalizedString("SMTP Port must not be empty.",
                                            comment: "Empty SMTP port server message")
                throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
            }

            guard let transSmtp = smtpSecurityTextfield.text, transSmtp != "" else {
                let msg = NSLocalizedString("Choose SMTP transport security method.",
                                            comment: "Empty SMTP transport security method")
                throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
            }

            //other
            guard let name = nameTextfield.text, name != "" else {
                let msg = NSLocalizedString("Account name must not be empty.",
                                            comment: "Empty account name message")
                throw AccountSettingsUserInputError.invalidInputAccountName(localizedMessage: msg)
            }

            guard let loginName = usernameTextfield.text, loginName != "" else {
                let msg = NSLocalizedString("Username must not be empty.",
                                            comment: "Empty username message")
                throw AccountSettingsUserInputError.invalidInputUserName(localizedMessage: msg)
            }

            return (addrImap: addrImap, portImap: portImap, transImap: transImap,
                    addrSmpt: addrSmpt, portSmtp: portSmtp, transSmtp: transSmtp, accountName: name,
                    loginName: loginName)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.count ?? 0
    }
    
    override func tableView(
        _ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel?[section]
    }
    
    override func tableView(
        _ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
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
        } else {
            return cell
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let ind = oauth2ReauthIndexPath, ind == indexPath, let address = viewModel?.email {
            oauth2ActivityIndicator.startAnimating()

            // don't accept errors form other places
            shouldHandleErrors = false

            oauthViewModel.delegate = self
            oauthViewModel.authorize(
                authorizer: appConfig.oauth2AuthorizationFactory.createOAuth2Authorizer(),
                emailAddress: address,
                viewController: self)
        }
    }

    // MARK: - Actions
    
    fileprivate func popViewController() {
         //!!!: see IOS-1608 this is a patch as we have 2 navigationControllers and need to pop to the previous view.
            (navigationController?.parent as? UINavigationController)?.popViewController(animated: true)
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {

        guard let isSplitViewShown = splitViewController?.isCollapsed else {
            return
        }
        if isSplitViewShown {
            popViewController()
        }
    }

    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
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

            showSpinnerAndDisableUI()
            viewModel?.update(loginName: validated.loginName, name: validated.accountName,
                              password: password, imap: imap, smtp: smtp,
                              keySyncEnable: keySyncEnable)
        } catch {
            informUser(about: error)
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        current = textField
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == passwordTextfield {
            passWordChanged = true
        }
        if textField == smtpPortTextfield || textField == imapPortTextfield {
            if string.isBackspace {
                return true
            }
            return string.isDigits
        }

        return true
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let vm = viewModel {
            return vm.svm.size
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if let vm = viewModel {
            return vm.svm[row]
        }
        return nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        if let c = current, let vm = viewModel {
            c.text = vm.svm[row]
            self.view.endEditing(true)
        }
    }
}

// MARK: - Error Handling

extension AccountSettingsTableViewController {
    public func handleLoginError(error: Error) {
        Log.shared.error("%@", "\(error)")
        UIUtils.show(error: error, inViewController: self)
    }
}

// MARK: - AccountVerificationResultDelegate

extension AccountSettingsTableViewController: AccountVerificationResultDelegate {
    func didVerify(result: AccountVerificationResult) {
        GCD.onMain() {
            self.hideSpinnerAndEnableUI()
            switch result {
            case .ok:
                //self.navigationController?.popViewController(animated: true)
                self.popViewController()
            case .imapError(let err):
                self.handleLoginError(error: err)
            case .smtpError(let err):
                self.handleLoginError(error: err)
            case .noImapConnectData, .noSmtpConnectData:
                self.handleLoginError(error: LoginViewController.LoginError.noConnectData)
            }
        }
    }
}

// MARK: - OAuth2AuthViewModelDelegate

extension AccountSettingsTableViewController: OAuth2AuthViewModelDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        oauth2ActivityIndicator.stopAnimating()

        shouldHandleErrors = true

        if let err = oauth2Error {
            self.handleLoginError(error: err)
            return
        }
        guard let token = accessToken else {
            self.handleLoginError(error: OAuth2AuthViewModelError.noToken)
            return
        }
        viewModel?.updateToken(accessToken: token)
    }
}

// MARK: - SPINNER

extension AccountSettingsTableViewController {
    /// Shows the spinner and disables UI parts that could lead to
    /// launching another verification while one is already in process.
    private func showSpinnerAndDisableUI() {
        doneButton.isEnabled = false

        spinner.center =
            CGPoint(x: tableView.frame.width / 2,
                    y:
                (tableView.frame.height / 2) - (navigationController?.navigationBar.frame.height
                    ?? 0.0))
        spinner.superview?.bringSubviewToFront(spinner)
        tableView.isUserInteractionEnabled = false
        spinner.startAnimating()
    }

    /// Hides the spinner and enables all UI elements again.
    private func hideSpinnerAndEnableUI() {
        doneButton.isEnabled = true
        tableView.isUserInteractionEnabled = true
        spinner.stopAnimating()
    }
}
