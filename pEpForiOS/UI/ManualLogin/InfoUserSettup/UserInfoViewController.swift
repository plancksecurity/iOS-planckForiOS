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

final class UserInfoViewController: BaseViewController, TextfieldResponder {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    var fields = [UITextField]()
    var responder = 0

    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
    var model: VerifiableAccountProtocol?

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

        var vm = viewModelOrCrash()
        vm.loginName = vm.loginName ?? vm.address

        fields = manualAccountSetupContainerView.manualSetupViewTextFeilds()
        setUpViewLocalizableTexts()
        setUpTextFieldsInputTraits()
        updateAutoFillForNextViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateView(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        firstResponder(!viewModelOrCrash().isValidName)
    }

    /// Update view state from the view model
    /// - Parameter animated: this property only apply to  items with animations, list AnimatedPlaceholderTextFields
    func updateView(animated: Bool = true) {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        var vm = viewModelOrCrash()

        setupView.firstTextField.set(text: vm.loginName, animated: animated)
        setupView.secondTextField.set(text: vm.address, animated: animated)
        setupView.thirdTextField.set(text: vm.password, animated: animated)
        setupView.fourthTextField.set(text: vm.userName, animated: animated)

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
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return true
        }
        if textField == setupView.fourthTextField,
            viewModelOrCrash().isValidUser {
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
        var vm = viewModelOrCrash()
        vm.keySyncEnable = isOn
    }

    func didChangeFirst(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.loginName = textField.text
        model = vm
        updateAutoFillForNextViews()
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.address = textField.text
        model = vm
        updateView()
    }

    func didChangeThird(_ textField: UITextField) {
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
        handleGoToNextView()
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
        view.endEditing(true)
        switch segue.destination {
        case let iMAPSettingsViewController as IMAPSettingsViewController:
            iMAPSettingsViewController.appConfig = appConfig
            iMAPSettingsViewController.model = model
        default:
            break
        }

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
    private func handleGoToNextView() {
        guard viewModelOrCrash().isValidUser else {
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

        let emailPlaceholder = NSLocalizedString("E-mail Address", comment: "Email address placeholder for manual account setup")
        setupView.secondTextField.placeholder = emailPlaceholder

        let passwordPlaceholder = NSLocalizedString("Password", comment: "Password placeholder for manual account setup")
        setupView.thirdTextField.placeholder = passwordPlaceholder

        let displayNamePlaceholder = NSLocalizedString("Display Name", comment: "Display Name placeholder for manual account setup")
        setupView.fourthTextField.placeholder = displayNamePlaceholder
    }

    private func updateAutoFillForNextViews() {
        var vm = viewModelOrCrash()
        vm.loginNameIMAP = vm.loginName
        vm.loginNameSMTP = vm.loginName
    }
}
