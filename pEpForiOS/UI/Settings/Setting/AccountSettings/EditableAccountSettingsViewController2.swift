//
//  EditableAccountSettingsViewController2.swift
//  pEp
//
//  Created by Martín Brude on 04/12/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class EditableAccountSettingsViewController2: UIViewController {

    var viewModel : EditableAccountSettingsViewModel2?

    @IBOutlet private var tableView: UITableView!
    private var firstResponder: UITextField?
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Account", comment: "Editable Account Settings view title")
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.hideSeperatorForEmptyCells()
        UIHelper.variableContentHeight(tableView)
        setKeyboardHandling()
    }

    @IBAction func saveButtonTapped() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        firstResponder?.resignFirstResponder()
        vm.handleSaveButtonPressed()
    }

    @IBAction func cancelButtonTapped() {
        dismissYourself()
    }
}

// MARK: - UITableViewDataSource

extension EditableAccountSettingsViewController2: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }

        return vm.sections[section].rows.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AccountSettingsTableViewCell.identifier) as? AccountSettingsTableViewCell else {
            Log.shared.errorAndCrash("Can't dequeue cell")
            return UITableViewCell()
        }
        guard let row = vm.sections[indexPath.section].rows[indexPath.row] as? AccountSettingsViewModel.DisplayRow else {
            Log.shared.errorAndCrash("Can't get row")
            return cell
        }
        cell.configure(with: row, for: traitCollection)
        if row.type == .tranportSecurity {
            cell.valueTextfield.inputView = pickerView
        }
        cell.valueTextfield.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate

extension EditableAccountSettingsViewController2: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
            Log.shared.errorAndCrash("pEpHeaderView doesn't exist!")
            return nil
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return nil
        }
        headerView.title = vm.sections[section].title.uppercased()
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - EditableAccountSettingsDelegate2

extension EditableAccountSettingsViewController2: EditableAccountSettingsDelegate2 {
    func setLoadingView(visible: Bool) {
        LoadingInterface.setLoadingView(visible: visible)
    }

    func showAlert(error: Error) {
        UIUtils.show(error: error)
    }

    func dismissYourself() {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - UITextFieldDelegate

extension EditableAccountSettingsViewController2: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        guard let cell = textField.superviewOfClass(ofClass: AccountSettingsTableViewCell.self) else {
            Log.shared.errorAndCrash("Cell not found")
            return
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Log.shared.errorAndCrash("indexPath not found")
            return
        }
        vm.handleRowDidChange(at:indexPath, value: textField.text ?? "")
    }
}

// MARK: - UIPickerViewDataSource

extension EditableAccountSettingsViewController2: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }

        return vm.numberOfTransportSecurityOptions
    }
}

// MARK: - UIPickerViewDelegate

extension EditableAccountSettingsViewController2: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return nil
        }
        return vm.transportSecurityOption(atIndex: row)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        firstResponder?.text = vm.transportSecurityOption(atIndex: row)
        dismissKeyboard()
    }
}

// MARK: - Accessibility

extension EditableAccountSettingsViewController2 {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
}

// MARK: - Keyboard Handling

extension EditableAccountSettingsViewController2 {

    private func setKeyboardHandling() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        if notification.name == UIResponder.keyboardWillHideNotification {
            tableView.contentInset = .zero
        } else {
            let bottomPadding: CGFloat = 50.0
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom + bottomPadding, right: 0)
        }
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
}
