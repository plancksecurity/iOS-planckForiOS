//
//  AccountSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 12/22/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class AccountSettingsTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
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
        
        guard let addi = imapServerTextfield.text, addi != "",
            let porti = imapPortTextfield.text, porti != "",
            let transi = imapSecurityTextfield.text, transi != "" else {
            return
        }

        let imap = (addi, porti, transi)

        guard let adds = smtpServerTextfield.text, adds != "",
            let ports = smtpPortTextfield.text, ports != "",
            let transs = smtpSecurityTextfield.text, transs != "" else {
            return
        }
        let smtp = (adds, ports, transs)

        if let name = nameTextfield.text, name != "", let loginName = usernameTextfield.text, loginName != "" {
            viewModel?.update(loginName: loginName, name: name, password: passwordTextfield.text, imap: imap, smtp: smtp)
            navigationController?.popViewController(animated: true)
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
