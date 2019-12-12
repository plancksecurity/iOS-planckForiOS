//
//  SMTPSettingsViewController.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel
import PantomimeFramework

final class SMTPSettingsViewController: BaseViewController, TextfieldResponder {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
    var model: VerifiableAccountProtocol?

    var fields = [UITextField]()
    var responder = 0
    var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        manualAccountSetupContainerView.delegate = self
        manualAccountSetupContainerView.textFieldsDelegate = self
        manualAccountSetupContainerView.pEpSyncViewIsHidden = true

        fields = manualAccountSetupContainerView.manualSetupViewTextFeilds()
        setUpViewLocalizableTexts()
        setUpTextFieldsInputTraits()
        setUpContainerView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateView(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        firstResponder(viewModelOrCrash().loginNameSMTP == nil)
    }

    @IBAction func didTapOnView(_ sender: Any) {
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate

extension SMTPSettingsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        changedResponder(textField)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //Nil case is handle in setupView getter
            return true
        }
        if textField == setupView.fourthTextField {
            view.endEditing(true)
            alertWithSecurityValues(textField)
            return false
        }
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //Error handle in setupView getter
            return true
        }
        if textField == setupView.thirdTextField {
            guard let text = textField.text as NSString? else {
                Log.shared.errorAndCrash("Fail to downcast from String to NSString")
                return true
            }
            let textFieldText = text.replacingCharacters(in: range, with: string)
            return UInt16(textFieldText) != nil || textFieldText.isEmpty
        }
        return true
    }
}

// MARK: - ManualAccountSetupViewDelegate

extension SMTPSettingsViewController: ManualAccountSetupViewDelegate {
    func didPressCancelButton() {
        navigationController?.popViewController(animated: true)
    }

    func didPressNextButton() {
        do {
            try verifyAccount()
            hideKeybord()
        } catch {
            let errorTopic = NSLocalizedString("Empty Field",
                                               comment: "Title of alert: a required field is empty")
            isCurrentlyVerifying =  false

            var errorMessage = ""

            if let verifiableError = error as? VerifiableAccountValidationError {
                switch verifiableError {
                case .invalidUserData:
                    errorMessage = NSLocalizedString("Some mandatory fields are empty",
                                                     comment: "Message of alert: a required field is empty")
                default:
                    Log.shared.errorAndCrash("Unhandled case in SMTPSettingsViewController")
                }
            } else {
                errorMessage = error.localizedDescription
            }
            informUser(about: errorMessage, title: errorTopic)
        }
    }

    func didChangeFirst(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.loginNameSMTP = textField.text
        model = vm
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.serverSMTP = textField.text
    }

    func didChangeThird(_ textField: UITextField) {
        guard let text = textField.text,
            let port = UInt16(text) else {
                //If not UInt16 then do nothing. Example empty string
                return
        }
        var vm = viewModelOrCrash()
        vm.portSMTP = port
    }

    func didChangeFourth(_ textField: UITextField) {
        //Do nothing, changes saved in model and textField in the bock of alert
    }
}

// MARK: - SegueHandlerType

extension SMTPSettingsViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case noSegue
        case backToEmailListSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        switch segueIdentifier(for: segue) {
        case .backToEmailListSegue:
            // nothing to do, since it's an unwind segue the targets already are configured
            break
        default:()
        }
    }
}

// MARK: - VerifiableAccountDelegate

extension SMTPSettingsViewController: VerifiableAccountDelegate {
    func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try model?.save() { [weak self] success in
                    DispatchQueue.main.async { [weak self] in
                        guard let me = self else {
                            Log.shared.errorAndCrash("Lost MySelf")
                            return
                        }
                        switch success {
                        case true:
                            me.isCurrentlyVerifying = false
                            me.performSegue(withIdentifier: .backToEmailListSegue, sender: me)
                        case false:
                            me.isCurrentlyVerifying = false
                            UIUtils.show(error: VerifiableAccountValidationError.invalidUserData, inViewController: me)
                        }
                    }
                }
            } catch {
                Log.shared.errorAndCrash(error: error)
            }
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                me.isCurrentlyVerifying = false
                UIUtils.show(error: error, inViewController: me)
            }
        }
    }
}

// MARK: - Helpers

extension SMTPSettingsViewController {
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

// MARK: - Private

extension SMTPSettingsViewController {
    /// Update view state from view model
    /// - Parameter animated: this property only apply to  items with animations, list AnimatedPlaceholderTextFields
    private func updateView(animated: Bool = true) {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        var vm = viewModelOrCrash()

        vm.loginNameSMTP = vm.loginNameSMTP ?? vm.address

        setupView.firstTextField.set(text: vm.loginNameSMTP ?? vm.address, animated: animated)
        setupView.secondTextField.set(text: vm.serverSMTP, animated: animated)
        setupView.thirdTextField.set(text: String(vm.portSMTP), animated: animated)
        setupView.fourthTextField.set(text: vm.transportSMTP.localizedString(), animated: animated)

        setupView.pEpSyncSwitch.isOn = vm.keySyncEnable

        setupView.nextButton.isEnabled = vm.isValidUser
        setupView.nextRightButton.isEnabled = vm.isValidUser

        if isCurrentlyVerifying {
            LoadingInterface.showLoadingInterface()
        } else {
            LoadingInterface.removeLoadingInterface()
        }
        navigationItem.rightBarButtonItem?.isEnabled = !isCurrentlyVerifying
    }

    /// Triggers verification for given data.
    ///
    /// - Throws: AccountVerificationError
    private func verifyAccount() throws {
        guard var viewModel = model else {
            Log.shared.errorAndCrash("No view model in STMP ViewController")
            return
        }
        isCurrentlyVerifying =  true
        viewModel.verifiableAccountDelegate = self
        try viewModel.verify()
    }

    private func informUser(about message: String, title: String) {
        let alert = UIAlertController.pEpAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert)
        let cancelAction = UIAlertAction(title:
            NSLocalizedString("OK", comment: "OK button for invalid accout settings user input alert"),
                                         style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func hideKeybord() {
        view.endEditing(true)
    }

    private func setUpTextFieldsInputTraits() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //Error handle in setupView getter
            return
        }

        setupView.thirdTextField.keyboardType = .numberPad
    }

    private func setUpViewLocalizableTexts() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //Error handle in setupView getter
            return
        }

        setupView.titleLabel.text = NSLocalizedString("SMTP", comment: "Title manual account SMTP setup")

        let nextButtonTittle = NSLocalizedString("Finish", comment: "Finish button title for manual account SMTP setup")
        setupView.nextButton.setTitle(nextButtonTittle, for: .normal)
        setupView.nextRightButton.setTitle(nextButtonTittle, for: .normal)

        let cancelButtonTittle = NSLocalizedString("Back", comment: "Cancel button title for manual account SMTP setup")
        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)
        setupView.cancelLeftButton.setTitle(cancelButtonTittle, for: .normal)

        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account SMTP setup")
        setupView.firstTextField.placeholder = userNamePlaceholder

        let serverPlaceholder = NSLocalizedString("Server", comment: "Server placeholder for manual account SMTP setup")
        setupView.secondTextField.placeholder = serverPlaceholder

        let portPlaceholder = NSLocalizedString("Port", comment: "Port placeholder for manual account SMTP setup")
        setupView.thirdTextField.placeholder = portPlaceholder

        let TransportSecurityPlaceholder = NSLocalizedString("Transport Security", comment: "TransportSecurity placeholder for manual account SMTP setup")
        setupView.fourthTextField.placeholder = TransportSecurityPlaceholder
    }

    private func alertWithSecurityValues(_ sender: UITextField) {
        let alertController = UIAlertController.pEpAlertController(
            title: NSLocalizedString("Transport protocol",
                                     comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                                       comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)
        let block: (ConnectionTransport) -> () = { transport in
            self.model?.transportSMTP = transport
            sender.text = transport.localizedString()
        }

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sender
            popoverPresentationController.sourceRect = sender.bounds
        }

        alertController.setupActionFromConnectionTransport(.plain, block: block)
        alertController.setupActionFromConnectionTransport(.TLS, block: block)
        alertController.setupActionFromConnectionTransport(.startTLS, block: block)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel for an alert view"),
            style: .cancel) { (action) in}
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) {}
    }

    private func setUpContainerView() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            setupView.scrollView.isScrollEnabled = false
        }
    }
}
