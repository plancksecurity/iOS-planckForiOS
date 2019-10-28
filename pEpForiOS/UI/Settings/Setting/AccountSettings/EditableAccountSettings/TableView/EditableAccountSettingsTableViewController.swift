//
//  EditableAccountSettingsTableViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class EditableAccountSettingsTableViewController: BaseTableViewController {
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
    @IBOutlet weak var securityPicker: UIPickerView!

    var viewModel: EditableAccountSettingsTableViewModel?

    private var firstResponder: UITextField?
    private var passWordChanged = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
    }
}


// MARK: - UITextFieldDelegate

extension EditableAccountSettingsTableViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = textField
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        switch textField {
        case imapSecurityTextfield:
            viewModel?.imapSecurity = textField.text
        case smtpSecurityTextfield:
            viewModel?.smtpSecurity = textField.text
        case imapPortTextfield:
            viewModel?.imapPort = textField.text
        case smtpPortTextfield:
            viewModel?.smtpPort = textField.text
        case usernameTextfield:
            viewModel?.username = textField.text
        case nameTextfield:
            viewModel?.loginName = textField.text
        case passwordTextfield:
            viewModel?.password = textField.text
            passWordChanged = true
        case smtpPortTextfield:
            viewModel?.smtpServerTextfieldText = textField.text
            return string.isBackspace ? true : string.isDigits
        case imapPortTextfield:
            viewModel?.imapServerTextfieldText = textField.text
            return string.isBackspace ? true : string.isDigits
        default:
            break
        }
        return true
    }
}


// MARK: - UIPickerViewDataSource

extension EditableAccountSettingsTableViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }
        return viewModel.securityViewModelvm.size
    }
}


// MARK: - UIPickerViewDelegate

extension EditableAccountSettingsTableViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {

        guard let viewModel = viewModel else { return nil }
        return viewModel.securityViewModelvm[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        guard let firstResponder = firstResponder, let viewModel = viewModel else { return }
        firstResponder.text = viewModel.securityViewModelvm[row]
        view.endEditing(true)
    }
}


// MARK: - UITableViewDataSource

extension EditableAccountSettingsTableViewController {
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
}


// MARK: - Private

extension EditableAccountSettingsTableViewController {
    private func setUpView() {
        smtpSecurityTextfield.inputView = securityPicker
        imapSecurityTextfield.inputView = securityPicker
    }
}


// MARK: - Helping Structures

extension EditableAccountSettingsTableViewController {
    struct TableFieldsData {
        let nameTextfield: String?
        let emailTextfield: String?
        let usernameTextfield: String?
        let smtpPortTextfield: String?
        let passwordTextfield: String?
        let imapPortTextfield: String?
        let smtpServerTextfield: String?
        let imapServerTextfield: String?
        let imapSecurityTextfield: String?
        let smtpSecurityTextfield: String?
    }
}
