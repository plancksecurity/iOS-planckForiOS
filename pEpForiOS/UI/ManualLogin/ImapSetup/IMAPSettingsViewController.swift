//
//  IMAPSettingsViewController.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import PantomimeFramework
import MessageModel

extension UIAlertController {
    func setupActionFromConnectionTransport(_ transport: ConnectionTransport,
                                            block: @escaping (ConnectionTransport) -> ()) {
        let action = UIAlertAction(title: transport.localizedString(), style: .default,
                                   handler: { action in
            block(transport)
        })
        addAction(action)
    }
}

final class IMAPSettingsViewController: BaseViewController, TextfieldResponder, UITextFieldDelegate {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    var fields = [UITextField]()
    var responder = 0

    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
    var model: VerifiableAccountProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return
        }
        setupView.delegate = self
        setupView.textFieldsDelegate = self

        fields = manualSetupViewTextFeilds()
        setUpViewLocalizableTexts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(model?.serverIMAP == nil)
    }

    private func updateView() {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return
        }
        let vm = viewModelOrCrash()

        setupView.firstTextField.text = vm.userName
        setupView.secondTextField.text = vm.serverIMAP
        setupView.thirdTextField.text = String(vm.portIMAP)
        setupView.fourthTextField.text = vm.transportIMAP.localizedString()

        setupView.pEpSyncSwitch.isOn = vm.keySyncEnable

        setupView.nextButton.isEnabled = vm.isValidUser
        setupView.nextRightButton.isEnabled = vm.isValidUser
    }

    @IBAction func didTapOnView(_ sender: Any) {
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate

extension IMAPSettingsViewController: UITextViewDelegate {

    func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        changedResponder(textField)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return true
        }
        if textField == setupView.fourthTextField {
            alertWithSecurityValues(textField)
            return false
        }
        return true
    }
}

// MARK: - Navigation

extension IMAPSettingsViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case SMTPSettings
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .SMTPSettings:
            if let destination = segue.destination as? SMTPSettingsTableViewController {
                destination.appConfig = appConfig
                destination.model = model
            } else {
                Log.shared.errorAndCrash(
                    "Seque is .SMTPSettings, but controller is not a SMTPSettingsTableViewController")
            }
            break
        default:()
        }
    }
}

// MARK: - ManualAccountSetupViewDelegate

extension IMAPSettingsViewController: ManualAccountSetupViewDelegate {
    func didPressCancelButton() {
        navigationController?.popViewController(animated: true)
    }

    func didPressNextButton() {
        //TODO:!!! Ale
    }

    func didChangeFirst(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.userName = textField.text
        model = vm
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.serverIMAP = textField.text
    }

    func didChangeThierd(_ textField: UITextField) {
        guard let text = textField.text,
            let port = UInt16(text) else {
                Log.shared.errorAndCrash("Fail to get IMAP Port in Manual Setup")
                return
        }
        var vm = viewModelOrCrash()
        vm.portIMAP = port
    }

    func didChangeFourth(_ textField: UITextField) {
        //TODO: Ale
    }
}

// MARK: - Helpers

extension IMAPSettingsViewController {
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

extension IMAPSettingsViewController {
    private func manualSetupViewTextFeilds() -> [UITextField] {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return []
        }
        return [setupView.firstTextField,
                setupView.secondTextField,
                setupView.thirdTextField,
                setupView.fourthTextField]
    }

    private func setUpViewLocalizableTexts() {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return
        }

        setupView.titleLabel.text = NSLocalizedString("IMAP", comment: "Title for manual account IMAP setup")

        let nextButtonTittle = NSLocalizedString("Next", comment: "Next button title for manual account IMAP setup")
        setupView.nextButton.setTitle(nextButtonTittle, for: .normal)

        let cancelButtonTittle = NSLocalizedString("Back", comment: "Cancel button title for manual account IMAP setup")
        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)

        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account IMAP setup")
        setupView.firstTextField.placeholder = userNamePlaceholder

        let serverPlaceholder = NSLocalizedString("Server", comment: "Server placeholder for manual account IMAP setup")
        setupView.secondTextField.placeholder = serverPlaceholder

        let portPlaceholder = NSLocalizedString("Port", comment: "Port placeholder for manual account IMAP setup")
        setupView.thirdTextField.placeholder = portPlaceholder

        let TransportSecurityPlaceholder = NSLocalizedString("TransportSecurity", comment: "TransportSecurity placeholder for manual account IMAP setup")
        setupView.fourthTextField.placeholder = TransportSecurityPlaceholder
    }

    private func alertWithSecurityValues(_ sender: UIView) {
        let alertController = UIAlertController.pEpAlertController(
            title: NSLocalizedString("Transport protocol",
                                     comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                                       comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)
        let block: (ConnectionTransport) -> () = { transport in
            self.model?.transportIMAP = transport
            self.updateView()
        }

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sender
        }

        alertController.setupActionFromConnectionTransport(.plain, block: block)
        alertController.setupActionFromConnectionTransport(.TLS, block: block)
        alertController.setupActionFromConnectionTransport(.startTLS, block: block)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel for an alert view"),
            style: .cancel) { (action) in}
        alertController.addAction(cancelAction)
        present(alertController, animated: true) {}
    }
}
