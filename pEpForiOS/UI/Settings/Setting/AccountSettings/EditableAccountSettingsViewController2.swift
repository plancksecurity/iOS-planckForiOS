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


    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    var viewModel : EditableAccountSettingsViewModel2?
    @IBOutlet private var tableView: UITableView!

    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.hideSeperatorForEmptyCells()
        UIHelper.variableContentHeight(tableView)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @IBAction func saveButtonTapped() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
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

// MARK: - Accessibility

extension EditableAccountSettingsViewController2 {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
}

extension EditableAccountSettingsViewController2: UITextFieldDelegate {

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

        return vm.transportSecurityViewModel.numberOfOptions
    }
}

// MARK: - UIPickerViewDelegate

extension EditableAccountSettingsViewController2: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return nil
        }
        return vm.transportSecurityViewModel[row]
//
//        let title = viewModel.securityViewModelvm[row]
//        if title == firstResponder?.text, isTransportSecurityField() {
//            pickerView.selectRow(row, inComponent: 0, animated: true)
//        }
//        return title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

//        guard let firstResponder = firstResponder else { return }
//        firstResponder.text = viewModel.securityViewModelvm[row]
        view.endEditing(true)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIView {
    func superviewOfClass<T>(ofClass: T.Type) -> T? {
        var currentView: UIView? = self

        while currentView != nil {
            if currentView is T {
                break
            } else {
                currentView = currentView?.superview
            }
        }

        return currentView as? T
    }
}
