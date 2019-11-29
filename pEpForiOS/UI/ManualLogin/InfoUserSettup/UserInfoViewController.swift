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

class UserInfoViewController: BaseViewController, TextfieldResponder {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    var fields = [UITextField]()
    var responder = 0

    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
    var model: VerifiableAccountProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let setupView = manualAccountSetupContainerView.setupView else {
            //If SetupViewError is nil is handle in setupView getter
            return
        }
        setupView.delegate = self
        setupView.textFieldsDelegate = self

        fields = manualAccountSetupContainerView.manualSetupViewTextFeilds()
        setUpViewLocalizableTexts()
        setUpTextFieldsInputTraits()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(!viewModelOrCrash().isValidName)
    }

    /**
     Puts the model into the view, in case it was set by the invoking view controller.
     */
    func updateView() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //If SetupViewError is nil is handle in setupView getter
            return
        }
        let vm = viewModelOrCrash()

        setupView.firstTextField.text = vm.userName
        setupView.secondTextField.text = vm.address
        setupView.thirdTextField.text = vm.password

        setupView.pEpSyncSwitch.isOn = vm.keySyncEnable

        setupView.nextButton.isEnabled = vm.isValidUser
        setupView.nextRightButton.isEnabled = vm.isValidUser
    }

    @IBAction func didTapOnView(_ sender: Any) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension UserInfoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextResponder(textField)

        if viewModelOrCrash().isValidUser {
            performSegue(withIdentifier: .IMAPSettings , sender: self)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        changedResponder(textField)
    }
}

// MARK: - ManualAccountSetupViewDelegate

extension UserInfoViewController: ManualAccountSetupViewDelegate {
    func didChangePEPSyncSwitch(isOn: Bool) {
        var vm = viewModelOrCrash()
        vm.keySyncEnable = isOn
    }

    func didChangeFirst(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.loginName = textField.text
        model = vm
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.address = textField.text
        model = vm
        updateView()
    }

    func didChangeThierd(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.password = textField.text
        model = vm
        updateView()
    }

    func didChangeFourth(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.userName = textField.text
        model = vm
        updateView()
    }

    func didPressCancelButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func didPressNextButton() {
        guard viewModelOrCrash().isValidUser else {
            Log.shared.errorAndCrash("Next button enable with not ValidUser in ManualAccountSetupView")
            return
        }
        performSegue(withIdentifier: .IMAPSettings , sender: self)
    }
}

// MARK: - Helpers

extension UserInfoViewController {
    func viewModelOrCrash() -> VerifiableAccountProtocol {
        if let vm = model {
            return vm
        } else {
            Log.shared.errorAndCrash("No view model")
            let vm = BaseVerifiableAccount()
            model = vm
            return vm
        }
    }
}

// MARK: - Navigation

extension UserInfoViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case IMAPSettings
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .IMAPSettings:
            if let destination = segue.destination as? IMAPSettingsViewController {
                destination.appConfig = appConfig
                destination.model = model
            }
            break
        default:
            break
        }
    }
}

// MARK: - Private

extension UserInfoViewController {
    private func setUpTextFieldsInputTraits() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //If SetupViewError is nil is handle in setupView getter
            return
        }

        setupView.secondTextField.textContentType = .emailAddress
        setupView.secondTextField.keyboardType = .emailAddress

        setupView.thirdTextField.isSecureTextEntry = true
    }

    private func setUpViewLocalizableTexts() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //If SetupViewError is nil is handle in setupView getter
            return
        }

        setupView.titleLabel.text = NSLocalizedString("Account", comment: "Title for manual account setup")

        let nextButtonTittle = NSLocalizedString("Next", comment: "Next button title for manual account setup")
        setupView.nextButton.setTitle(nextButtonTittle, for: .normal)

        let cancelButtonTittle = NSLocalizedString("Cancel", comment: "Cancel button title for manual account setup")
        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)

        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account setup")
        setupView.firstTextField.placeholder = userNamePlaceholder

        let emailPlaceholder = NSLocalizedString("E-mail Address", comment: "Email address placeholder for manual account setup")
        setupView.secondTextField.placeholder = emailPlaceholder

        let passwordPlaceholder = NSLocalizedString("Password", comment: "Password placeholder for manual account setup")
        setupView.thirdTextField.placeholder = passwordPlaceholder

        let displayNamePlaceholder = NSLocalizedString("Display Name", comment: "Display Name placeholder for manual account setup")
        setupView.fourthTextField.placeholder = displayNamePlaceholder
    }
}
