//
//  AccountSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 12/22/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class AccountSettingsTableViewController: TableViewControllerBase, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
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

    var securityPicker: UIPickerView?

    var viewModel: AccountSettingsViewModel? = nil

    var current: UITextField?
    
     override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    func configureView() {
        self.nameTextfield.text = viewModel?.name
        self.emailTextfield.text = viewModel?.email
        self.usernameTextfield.text = viewModel?.loginName

        securityPicker = UIPickerView(frame: CGRect(x: 0, y: 50, width: 100, height: 150))
        securityPicker?.delegate = self
        securityPicker?.dataSource = self
        securityPicker?.showsSelectionIndicator = true

        let imap = viewModel?.imapServer
        self.imapServerTextfield.text = imap?.address
        self.imapPortTextfield.text = imap?.port
        self.imapSecurityTextfield.text = imap?.transport
        self.imapSecurityTextfield.inputView = securityPicker
        self.imapSecurityTextfield.delegate = self
        self.imapSecurityTextfield.tag = 1

        let smtp = viewModel?.smtpServer
        self.smtpServerTextfield.text = smtp?.address
        self.smtpPortTextfield.text = smtp?.port
        self.smtpSecurityTextfield.text = smtp?.transport
        self.smtpSecurityTextfield.inputView = securityPicker
        self.smtpSecurityTextfield.delegate = self
        self.smtpSecurityTextfield.tag = 2
    }

    private func informUser(about error:Error) {
        let alert = UIAlertController(title: NSLocalizedString("Invalid Input", comment: "Title of invalid accout settings user input alert"),
                                      message: error.localizedDescription,
                                      preferredStyle: UIAlertControllerStyle.alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK button for invalid accout settings user input alert"),
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
                let msg = NSLocalizedString("IMAP server must not be empty.", comment: "Empty IMAP server message")
                throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
            }

            guard let portImap = imapPortTextfield.text, portImap != "" else {
                let msg = NSLocalizedString("IMAP Port must not be empty.", comment: "Empty IMAP port server message")
                throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
            }

            guard let transImap = imapSecurityTextfield.text, transImap != "" else {
                let msg = NSLocalizedString("Choose IMAP transport security method.", comment: "Empty IMAP transport security method")
                throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
            }

            //SMTP
            guard let addrSmpt = smtpServerTextfield.text, addrSmpt != "" else {
                let msg = NSLocalizedString("SMTP server must not be empty.", comment: "Empty SMTP server message")
                throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
            }

            guard let portSmtp = smtpPortTextfield.text, portSmtp != "" else {
                let msg = NSLocalizedString("SMTP Port must not be empty.", comment: "Empty SMTP port server message")
                throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
            }

            guard let transSmtp = smtpSecurityTextfield.text, transSmtp != "" else {
                let msg = NSLocalizedString("Choose SMTP transport security method.", comment: "Empty SMTP transport security method")
                throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
            }

            //other
            guard let name = nameTextfield.text, name != "" else {
                let msg = NSLocalizedString("Account name must not be empty.", comment: "Empty account name message")
                throw AccountSettingsUserInputError.invalidInputAccountName(localizedMessage: msg)
            }

            guard let loginName = usernameTextfield.text, loginName != "" else {
                let msg = NSLocalizedString("Username must not be empty.", comment: "Empty username message")
                throw AccountSettingsUserInputError.invalidInputUserName(localizedMessage: msg)
            }

            return (addrImap: addrImap, portImap: portImap, transImap: transImap,
                    addrSmpt: addrSmpt, portSmtp: portSmtp, transSmtp: transSmtp, accountName: name,
                    loginName: loginName)
    }

    // MARK: - UItableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        var value = 0
        if let vm = viewModel {
            value = vm.count
        }
        return value
    }
    
    override func tableView(
        _ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel?[section]
    }
    
    override func tableView(
        _ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    // MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
      let _ =  navigationController?.popViewController(animated: true)
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
            viewModel?.update(loginName: validated.loginName, name: validated.accountName,
                              imap: imap, smtp: smtp)
            navigationController?.popViewController(animated: true)
        } catch {
            informUser(about: error)
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        current = textField
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

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let vm = viewModel {
            return vm.svm[row]
        }
        return nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let c = current, let vm = viewModel {
            c.text = vm.svm[row]
        }
    }
}
