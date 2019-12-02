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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        firstResponder(model?.serverSMTP == nil)
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
            informUser(about: error, title: errorTopic)
        }
    }

    func didChangeFirst(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.loginName = textField.text
        model = vm
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.serverSMTP = textField.text
    }

    func didChangeThierd(_ textField: UITextField) {
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
    private func updateView() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //If SetupViewError is nil is handle in setupView getter
            return
        }
        let vm = viewModelOrCrash()

        setupView.firstTextField.text = vm.loginName
        setupView.secondTextField.text = vm.serverSMTP
        setupView.thirdTextField.text = String(vm.portSMTP)
        setupView.fourthTextField.text = vm.transportSMTP.localizedString()

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
        isCurrentlyVerifying =  true
        model?.verifiableAccountDelegate = self
        try model?.verify()
    }

    private func informUser(about error: Error, title: String) {
        let alert = UIAlertController.pEpAlertController(
            title: title,
            message: error.localizedDescription,
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

        let cancelButtonTittle = NSLocalizedString("Back", comment: "Cancel button title for manual account SMTP setup")
        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)

        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account SMTP setup")
        setupView.firstTextField.placeholder = userNamePlaceholder

        let serverPlaceholder = NSLocalizedString("Server", comment: "Server placeholder for manual account SMTP setup")
        setupView.secondTextField.placeholder = serverPlaceholder

        let portPlaceholder = NSLocalizedString("Port", comment: "Port placeholder for manual account SMTP setup")
        setupView.thirdTextField.placeholder = portPlaceholder

        let TransportSecurityPlaceholder = NSLocalizedString("TransportSecurity", comment: "TransportSecurity placeholder for manual account SMTP setup")
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
}
