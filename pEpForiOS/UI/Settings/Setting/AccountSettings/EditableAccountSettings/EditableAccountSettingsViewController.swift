//
//  EditableAccountSettingsViewController.swift
//  pEp
//
//  Created by Martín Brude on 04/12/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class EditableAccountSettingsViewController: UIViewController {

    final var viewModel: EditableAccountSettingsViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var cancelButton: UIBarButtonItem!

    private var firstResponder: UITextField?
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        return picker
    }()

    private var shouldShowCancel: Bool {
        return splitViewController?.isCollapsed ?? true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Account", comment: "Editable Account Settings view title")
        tableView.register(PEPHeaderView.self, forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.hideSeperatorForEmptyCells()
        UIHelper.variableContentHeight(tableView)
        tableView.allowsSelection = true
        setKeyboardHandling()
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        showHideCancelButton()
    }

    @IBAction func saveButtonTapped() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        // Triggers didEndEditing, which is needed to validate the input.
        firstResponder?.resignFirstResponder()
        vm.handleSaveButtonPressed()
    }

    @IBAction func cancelButtonTapped() {
        dismissYourself()
    }
}

// MARK: - UITableViewDataSource

extension EditableAccountSettingsViewController: UITableViewDataSource {

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

        let row = vm.sections[indexPath.section].rows[indexPath.row]

        switch row.type {
        case .certificate:
            guard let row = row as? AccountSettingsViewModel.ActionRow else {
                Log.shared.errorAndCrash("Can't get row")
                return cell
            }
            cell.configureActionRow(with: row, for: traitCollection)
            cell.valueTextfield.delegate = self
            return cell
        default:
            guard let row = row as? AccountSettingsViewModel.DisplayRow else {
                Log.shared.errorAndCrash("Can't get row")
                return cell
            }
            cell.configureDisplayRow(with: row, for: traitCollection)
            if row.type == .tranportSecurity {
                cell.valueTextfield.inputView = pickerView
            }
            cell.valueTextfield.delegate = self
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension EditableAccountSettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if let row = vm.sections[indexPath.section].rows[indexPath.row] as? AccountSettingsViewModel.ActionRow,
           let action = row.action {
            action()
        }
    }
}

// MARK: - EditableAccountSettingsDelegate2

extension EditableAccountSettingsViewController: EditableAccountSettingsDelegate {

    func setLoadingView(visible: Bool) {
        LoadingInterface.setLoadingView(visible: visible)
    }

    func showAlert(error: Error) {
        UIUtils.show(error: error)
    }

    func dismissYourself() {
        navigationController?.popViewController(animated: true)
    }

    func showEditCertificate() {
        guard let vc = UIStoryboard.init(name: "AccountCreation", bundle: nil).instantiateViewController(withIdentifier: ClientCertificateManagementViewController.storyboardIdentifier) as? ClientCertificateManagementViewController else {
            return
        }
        let nextViewModel = viewModel?.clientCertificateManagementViewModel()
        nextViewModel?.delegate = vc
        vc.viewModel = nextViewModel
        navigationController?.modalPresentationStyle = .fullScreen
        vc.modalPresentationStyle = .overFullScreen
        vc.hidesBottomBarWhenPushed = true
        present(vc, animated: true)

//        performSegue(withIdentifier: "showClientCertificateManagementView", sender: self)
    }
}

// MARK: - SegueHandlerType

extension EditableAccountSettingsViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case showClientCertificateManagementView
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        
        switch segueIdentifier(for: segue) {
        case .showClientCertificateManagementView:
            guard let vc = segue.destination as? ClientCertificateManagementViewController else {
                Log.shared.errorAndCrash("fail to cast to ClientCertificateManagementViewController")
                return
            }
            let nextViewModel = vm.clientCertificateManagementViewModel()
            nextViewModel.delegate = vc
            vc.viewModel = nextViewModel
        }
    }
}

// MARK: - UITextFieldDelegate

extension EditableAccountSettingsViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let row = getRow(of: textField)
        return row.type != .certificate
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = textField
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        let row = getRow(of: textField)
        if row.type == .tranportSecurity {
            guard let displayRow = row as? AccountSettingsViewModel.DisplayRow else {
                return
            }
            let index = vm.transportSecurityIndex(for: displayRow.text)
            pickerView.selectRow(index, inComponent: 0, animated: true)
            textField.tintColor = .clear
        }
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
            //Valid case: indexPath not found
            return
        }
        vm.handleRowDidChange(at:indexPath, value: textField.text ?? "")
    }

    // MARK: - Private

    private func getRow(of textField: UITextField) -> AccountSettingsRowProtocol {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return AccountSettingsViewModel.DisplayRow(type: .email, title: "", text: "", cellIdentifier: "")
        }
        guard let indexPath = indexPathOfCellWith(textField: textField) else {
            Log.shared.errorAndCrash("Textfield begins editing doesn't belong to any row")
            return AccountSettingsViewModel.DisplayRow(type: .email, title: "", text: "", cellIdentifier: "")
        }
        return vm.sections[indexPath.section].rows[indexPath.row]
    }

    private func indexPathOfCellWith(textField: UITextField) -> IndexPath? {
        guard let cell = textField.superviewOfClass(ofClass: AccountSettingsTableViewCell.self) else {
            Log.shared.errorAndCrash("Cell not found")
            return nil
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Log.shared.errorAndCrash("indexPath not found")
            return nil
        }
        return indexPath
    }

}

// MARK: - UIPickerViewDataSource

extension EditableAccountSettingsViewController: UIPickerViewDataSource {

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

extension EditableAccountSettingsViewController: UIPickerViewDelegate {

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

extension EditableAccountSettingsViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
}

// MARK: - Keyboard Handling

extension EditableAccountSettingsViewController {

    private func setKeyboardHandling() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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

extension EditableAccountSettingsViewController {
    private func showHideCancelButton() {
        if shouldShowCancel {
            navigationItem.leftBarButtonItem = cancelButton
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
}
