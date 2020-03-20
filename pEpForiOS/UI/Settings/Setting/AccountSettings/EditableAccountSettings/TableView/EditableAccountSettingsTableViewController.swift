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
    @IBOutlet weak var passwordTextfield: UITextField!

    @IBOutlet weak var imapServerTextfield: UITextField!
    @IBOutlet weak var imapPortTextfield: UITextField!
    @IBOutlet weak var imapSecurityTextfield: UITextField!
    @IBOutlet weak var imapUsernameTextfield: UITextField!

    @IBOutlet weak var smtpServerTextfield: UITextField!
    @IBOutlet weak var smtpPortTextfield: UITextField!
    @IBOutlet weak var smtpSecurityTextfield: UITextField!
    @IBOutlet weak var smtpUsernameTextfield: UITextField!

    @IBOutlet weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet weak var securityPicker: UIPickerView!

    var viewModel: EditableAccountSettingsTableViewModel?

    private var firstResponder: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // we need to reload data for relayout cells - UITableView.automaticDimension
        reloadTable()
    }
}

// MARK: - UITextFieldDelegate

extension EditableAccountSettingsTableViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = textField
        reloadPickerIfNeeded()
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
        case nameTextfield:
            viewModel?.name = textField.text
        case passwordTextfield:
            viewModel?.password = textField.text
        case smtpServerTextfield:
            viewModel?.smtpServer?.address = textField.text
        case imapServerTextfield:
            viewModel?.imapServer?.address = textField.text
        case imapUsernameTextfield:
            viewModel?.imapUsername = textField.text
        case smtpUsernameTextfield:
            viewModel?.smtpUsername = textField.text
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
        if title == firstResponder?.text, isTransportSecurityField() {
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: pEpHeaderView.reuseIdentifier) as? pEpHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        headerView.title = viewModel?[section].uppercased() ?? ""
        return headerView
    }
}

// MARK: - EditableAccountSettingsTableViewModelDelegate

extension EditableAccountSettingsTableViewController: EditableAccountSettingsTableViewModelDelegate {
    func reloadTable() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let vm = me.viewModel else {
                Log.shared.errorAndCrash("Lost viewModel!")
                return
            }
            me.nameTextfield.text = vm.name
            me.emailTextfield.text = vm.email
            me.passwordTextfield.text = vm.password ?? "JustAPassword"
            me.passwordTextfield.layoutSubviews()

            me.imapServerTextfield.text = vm.imapServer?.address
            me.imapPortTextfield.text = vm.imapServer?.port
            me.imapSecurityTextfield.text = vm.imapServer?.transport
            me.imapUsernameTextfield.text = vm.imapUsername

            me.smtpServerTextfield.text = vm.smtpServer?.address
            me.smtpPortTextfield.text = vm.smtpServer?.port
            me.smtpSecurityTextfield.text = vm.smtpServer?.transport
            me.smtpUsernameTextfield.text = vm.smtpUsername

            me.tableView.reloadData()
        }
    }
}

// MARK: - Private

extension EditableAccountSettingsTableViewController {

    private func setUpView() {
        tableView.register(pEpHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: pEpHeaderView.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        smtpSecurityTextfield.inputView = securityPicker
        imapSecurityTextfield.inputView = securityPicker
    }

    private func isTransportSecurityField() -> Bool {
        return firstResponder == imapSecurityTextfield || firstResponder == smtpSecurityTextfield
    }

    private func reloadPickerIfNeeded() {
        if isTransportSecurityField(),
            let picker = firstResponder?.inputView as? UIPickerView {
            picker.reloadAllComponents()
        }
    }
}
