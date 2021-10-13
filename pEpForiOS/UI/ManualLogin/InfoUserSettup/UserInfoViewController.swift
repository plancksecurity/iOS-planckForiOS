//
//  UserInfoViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import MessageModel

final class UserInfoViewController: UIViewController {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    var fields = [UITextField]()
    var responder = 0

    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
    var verifiableAccount: VerifiableAccountProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        setupView.delegate = self
        setupView.textFieldsDelegate = self

        if UIDevice.current.userInterfaceIdiom == .pad {
            setupView.scrollView.isScrollEnabled = false
        }

        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        verifiableAccount.loginNameSMTP = verifiableAccount.loginNameSMTP ?? verifiableAccount.address
        verifiableAccount.loginNameIMAP = verifiableAccount.loginNameIMAP ?? verifiableAccount.address

        fields = manualAccountSetupContainerView.manualSetupViewTextFeilds()
        setUpViewLocalizableTexts()
        setUpTextFieldsInputTraits()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        firstResponder(!verifiableAccount.loginNameIsValid)
    }

    /// Update view state from the view model
    /// - Parameter animated: this property only apply to  items with animations, list AnimatedPlaceholderTextFields
    func updateView(animated: Bool = true) {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        guard let verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        setupView.firstTextField.set(text: verifiableAccount.loginNameIMAP, animated: animated)
        setupView.secondTextField.set(text: verifiableAccount.address, animated: animated)
        setupView.thirdTextField.isHidden = true
        setupView.fifthTextField.isHidden = true

        setupView.fourthTextField.set(text: verifiableAccount.userName, animated: animated)
        setupView.pEpSyncSwitch.isOn = verifiableAccount.keySyncEnable
        setupView.nextRightButton.isEnabled = verifiableAccount.isValidUser
    }
}

// MARK: - TextfieldResponder

extension UserInfoViewController: TextfieldResponder {

    @IBAction func didTapOnView(_ sender: Any) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension UserInfoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard
            let verifiableAccount = verifiableAccount,
            let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Invalid state")
            return true
        }
        if textField == setupView.fourthTextField,
           verifiableAccount.isValidUser {
            handleGoToNextView()
            return true
        }

        nextResponder(textField)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        changedResponder(textField)
    }
}

// MARK: - ManualAccountSetupViewDelegate

extension UserInfoViewController: ManualAccountSetupViewDelegate {

    func didChangePEPSyncSwitch(isOn: Bool) {
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        verifiableAccount.keySyncEnable = isOn
    }

    func didChangeFirst(_ textField: UITextField) {
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        verifiableAccount.loginNameIMAP = textField.text
        verifiableAccount.loginNameSMTP = textField.text
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        verifiableAccount.address = textField.text
        updateView()
    }


    func didChangeThird(_ textField: UITextField) { }

    func didChangeFourth(_ textField: UITextField) { }

    func didChangeFifth(_ textField: UITextField) {
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        verifiableAccount.userName = textField.text
        updateView()
    }

    func didPressCancelButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func didPressNextButton() {
        handleGoToNextView()
    }
}

// MARK: - Navigation

extension UserInfoViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case IMAPSettings
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        switch segue.destination {
        case let iMAPSettingsViewController as IMAPSettingsViewController:
            iMAPSettingsViewController.verifiableAccount = verifiableAccount
        default:
            break
        }

        switch segueIdentifier(for: segue) {
        case .IMAPSettings:
            if let destination = segue.destination as? IMAPSettingsViewController {
                destination.verifiableAccount = verifiableAccount
            }
            break
        default:
            break
        }
    }
}

// MARK: - Private

extension UserInfoViewController {
    private func handleGoToNextView() {
        guard
            let verifiableAccount = verifiableAccount,
            verifiableAccount.isValidUser else {
            Log.shared.errorAndCrash("Next button enable with not ValidUser in ManualAccountSetupView")
            return
        }
        performSegue(withIdentifier: .IMAPSettings , sender: self)
    }

    private func setUpTextFieldsInputTraits() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }

        setupView.firstTextField.textContentType = .emailAddress
        setupView.firstTextField.keyboardType = .emailAddress

        setupView.secondTextField.textContentType = .emailAddress
        setupView.secondTextField.keyboardType = .emailAddress

        setupView.thirdTextField.isSecureTextEntry = true
    }

    private func setUpViewLocalizableTexts() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }

        setupView.titleLabel.text = NSLocalizedString("ACCOUNT", comment: "Title for manual account setup")

        let nextButtonTittle = NSLocalizedString("Next", comment: "Next button title for manual account setup")
        setupView.nextButton.setTitle(nextButtonTittle, for: .normal)
        setupView.nextRightButton.setTitle(nextButtonTittle, for: .normal)

        let cancelButtonTittle = NSLocalizedString("Cancel", comment: "Cancel button title for manual account setup")
        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)
        setupView.cancelLeftButton.setTitle(cancelButtonTittle, for: .normal)

        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account setup")
        setupView.firstTextField.placeholder = userNamePlaceholder

        let emailPlaceholder = NSLocalizedString("Email Address", comment: "Email address placeholder for manual account setup")
        setupView.secondTextField.placeholder = emailPlaceholder

        let passwordPlaceholder = NSLocalizedString("Password", comment: "Password placeholder for manual account setup")
        setupView.thirdTextField.placeholder = passwordPlaceholder

        let displayNamePlaceholder = NSLocalizedString("Display Name", comment: "Display Name placeholder for manual account setup")
        setupView.fourthTextField.placeholder = displayNamePlaceholder
    }
}
