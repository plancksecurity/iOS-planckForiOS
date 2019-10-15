//
//  EditableAccountSettingsTableViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

//protocol EditableAcoountSettingsTableViewController: class {
//    func 
//}

class EditableAccountSettingsTableViewController: BaseTableViewController {
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

    private var current: UITextField?
    private var passWordChanged: Bool = false
    var viewModel: EditableAccountSettingsTableViewModel? = nil

    override func viewDidLoad() {
        setUpView()
    }

}

// MARK: - Private
extension EditableAccountSettingsTableViewController {
    private func setUpView() {
        let securityPicker = UIPickerView(frame: CGRect(x: 0, y: 50, width: 100, height: 150))
        securityPicker?.delegate = self
        securityPicker?.dataSource = self
        securityPicker?.showsSelectionIndicator = true

        self.smtpSecurityTextfield.inputView = securityPicker
        self.imapSecurityTextfield.inputView = securityPicker
    }
}


// MARK: - UITextFieldDelegate

extension EditableAccountSettingsTableViewController: UITextFieldDelegate {
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
}


// MARK: - UIPickerViewDelegate

extension EditableAccountSettingsTableViewController: UIPickerViewDelegate {
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


// MARK: - UITableViewDataSource

extension EditableAccountSettingsTableViewController: UITableViewDataSource {
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
