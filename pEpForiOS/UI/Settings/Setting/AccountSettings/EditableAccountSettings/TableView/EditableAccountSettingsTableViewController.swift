//
//  EditableAccountSettingsTableViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class EditableAccountSettingsTableViewController: UITableViewController {

    @IBOutlet private var stackViews: [UIStackView]!

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextfield: UITextField!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var emailTextfield: UITextField!
    @IBOutlet private weak var passwordLabel: UILabel!
    @IBOutlet private weak var passwordTextfield: UITextField!
    @IBOutlet private weak var imapServerLabel: UILabel!
    @IBOutlet private weak var imapServerTextfield: UITextField!
    @IBOutlet private weak var imapPortLabel: UILabel!
    @IBOutlet private weak var imapPortTextfield: UITextField!
    @IBOutlet private weak var imapSecurityTextfield: UITextField!
    @IBOutlet private weak var imapUsernameTextfield: UITextField!
    @IBOutlet private weak var imapTransportSecurityLabel: UILabel!
    @IBOutlet private weak var smtpServerTextfield: UITextField!
    @IBOutlet private weak var smtpPortTextfield: UITextField!
    @IBOutlet private weak var smtpSecurityTextfield: UITextField!
    @IBOutlet private weak var smtpUsernameTextfield: UITextField!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var passwordTableViewCell: UITableViewCell!
    @IBOutlet private weak var securityPicker: UIPickerView!
    @IBOutlet private weak var serverLabel: UILabel!
    @IBOutlet private weak var portLabel: UILabel!
    @IBOutlet private weak var transportSecurityLabel: UILabel!
    @IBOutlet private weak var smtpUsernameLabel: UILabel!
    
    var viewModel: EditableAccountSettingsTableViewModel?

    private var firstResponder: UITextField?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        configureView(for: traitCollection)
        setFonts()
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
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PEPHeaderView.reuseIdentifier) as? PEPHeaderView else {
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
            self?.nameTextfield.text = self?.viewModel?.name
            self?.emailTextfield.text = self?.viewModel?.email
            self?.passwordTextfield.text = self?.viewModel?.password ?? "JustAPassword"

            self?.imapServerTextfield.text = self?.viewModel?.imapServer?.address
            self?.imapPortTextfield.text = self?.viewModel?.imapServer?.port
            self?.imapSecurityTextfield.text = self?.viewModel?.imapServer?.transport
            self?.imapUsernameTextfield.text = self?.viewModel?.imapUsername

            self?.smtpServerTextfield.text = self?.viewModel?.smtpServer?.address
            self?.smtpPortTextfield.text = self?.viewModel?.smtpServer?.port
            self?.smtpSecurityTextfield.text = self?.viewModel?.smtpServer?.transport
            self?.smtpUsernameTextfield.text = self?.viewModel?.smtpUsername

            self?.tableView.reloadData()
        }
    }
}

// MARK: - Private

extension EditableAccountSettingsTableViewController {

    private func setUpView() {
        tableView.register(PEPHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PEPHeaderView.reuseIdentifier)
        tableView.delegate = self
        smtpSecurityTextfield.inputView = securityPicker
        imapSecurityTextfield.inputView = securityPicker
        setFonts()
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


//MARK : - Accessibility

extension EditableAccountSettingsTableViewController {

    /// To support dynamic font with a font size limit we have set the font by code.
    private func setFonts() {
        let font = UIFont.pepFont(style: .body, weight: .regular)

        //Name
        nameLabel.font = font
        nameTextfield.font = font

        //Email
        emailLabel.font = font
        emailTextfield.font = font

        //Password
        passwordLabel.font = font
        passwordTextfield.font = font

        //Server
        serverLabel.font = font
        imapServerTextfield.font = font

        //Port
        portLabel.font = font
        imapPortTextfield.font = font

        //Security
        transportSecurityLabel.font = font
        imapSecurityTextfield.font = font

        //SMTP Server
        smtpServerTextfield.font = font

        //SMTP Server Port
        smtpPortTextfield.font = font

        //SMTP Server Transport Security
        smtpSecurityTextfield.font = font

        //SMTP Server Username
        smtpUsernameLabel.font = font
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
        configureView(for: traitCollection)
      }
    }

    private func configureView(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        let axis : NSLayoutConstraint.Axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        let spacing : CGFloat = contentSize.isAccessibilityCategory ? 10.0 : 5.0

        stackViews.forEach {
            $0.axis = axis
            $0.spacing = spacing
        }
    }
}
