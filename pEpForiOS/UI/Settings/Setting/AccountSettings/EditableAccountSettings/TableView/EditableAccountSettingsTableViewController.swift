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

    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case imapSecurityTextfield:
            viewModel?.imapServer?.transport = textField.text
        case smtpSecurityTextfield:
            viewModel?.smtpServer?.transport = textField.text
        case imapPortTextfield:
            viewModel?.imapServer?.port = textField.text
        case smtpPortTextfield:
            viewModel?.smtpServer?.port = textField.text
        case usernameTextfield:
            viewModel?.loginName = textField.text
        case nameTextfield:
            viewModel?.name = textField.text
        case passwordTextfield:
            viewModel?.password = textField.text
        case smtpServerTextfield:
            viewModel?.smtpServer?.address = textField.text
        case imapServerTextfield:
            viewModel?.imapServer?.address = textField.text
        default:
            break
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        switch textField {
        case imapPortTextfield, smtpPortTextfield:
            return string.isBackspace ? true : string.isDigits
        default:
            return true
        }
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
        let title = viewModel.securityViewModelvm[row]
        if title == firstResponder?.text,
            firstResponder == imapSecurityTextfield || firstResponder == smtpSecurityTextfield {
            pickerView.selectRow(row, inComponent: 0, animated: true)
        }
        return title
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


// MARK: - EditableAccountSettingsTableViewModelDelegate

extension EditableAccountSettingsTableViewController: EditableAccountSettingsTableViewModelDelegate {
    func reloadTable() {
        DispatchQueue.main.async { [weak self] in
            self?.nameTextfield.text = self?.viewModel?.name
            self?.emailTextfield.text = self?.viewModel?.email
            self?.usernameTextfield.text = self?.viewModel?.loginName
            self?.passwordTextfield.text = self?.viewModel?.password ?? "JustAPassword"

            self?.imapServerTextfield.text = self?.viewModel?.imapServer?.address
            self?.imapPortTextfield.text = self?.viewModel?.imapServer?.port
            self?.imapSecurityTextfield.text = self?.viewModel?.imapServer?.transport

            self?.smtpServerTextfield.text = self?.viewModel?.smtpServer?.address
            self?.smtpPortTextfield.text = self?.viewModel?.smtpServer?.port
            self?.smtpSecurityTextfield.text = self?.viewModel?.smtpServer?.transport

            self?.tableView.reloadData()
        }
    }
}


// MARK: - Private

extension EditableAccountSettingsTableViewController {
    private func setUpView() {
        smtpSecurityTextfield.inputView = securityPicker
        imapSecurityTextfield.inputView = securityPicker
    }
}
