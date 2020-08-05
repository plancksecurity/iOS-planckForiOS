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

final class IMAPSettingsViewController: UIViewController, TextfieldResponder {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    var fields = [UITextField]()
    var responder = 0

    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
    var verifiableAccount: VerifiableAccountProtocol?

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
        guard let verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("No Verifiable account")
            return
        }
        firstResponder(verifiableAccount.loginNameIMAP == nil)
    }

    @IBAction func didTapOnView(_ sender: Any) {
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate

extension IMAPSettingsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        changedResponder(textField)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
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
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return true
        }
        if textField == setupView.thirdTextField {
            guard var text = textField.text,
                let range = Range(range, in: text) else {
                Log.shared.errorAndCrash("Fail to get textField text or range")
                return true
            }
            text.replaceSubrange(range, with: string)
            return UInt16(text) != nil || text.isEmpty
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
        view.endEditing(true)
        switch segueIdentifier(for: segue) {
        case .SMTPSettings:
            if let destination = segue.destination as? SMTPSettingsViewController {
                destination.verifiableAccount = verifiableAccount
            } else {
                Log.shared.errorAndCrash(
                    "Seque is .SMTPSettings, but controller is not a SMTPSettingsViewController")
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
        performSegue(withIdentifier: .SMTPSettings, sender: self)
    }

    func didChangeFirst(_ textField: UITextField) {
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("No Verifiable account")
            return
        }
        verifiableAccount.loginNameIMAP = textField.text
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("No Verifiable account")
            return
        }
        verifiableAccount.serverIMAP = textField.text
    }

    func didChangeThird(_ textField: UITextField) {
        guard let text = textField.text,
            let port = UInt16(text) else {
                //If not UInt16 then do nothing. Example empty string
                return
        }
        guard var verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("No Verifiable account")
            return
        }
        verifiableAccount.portIMAP = port
    }

    func didChangeFourth(_ textField: UITextField) {
        //Do nothing, changes saved in model and textField in the bock of alert
    }
}

// MARK: - Private

extension IMAPSettingsViewController {
    private func setUpTextFieldsInputTraits() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        setupView.thirdTextField.keyboardType = .numberPad
    }

    private func setUpViewLocalizableTexts() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }

        setupView.titleLabel.text = NSLocalizedString("IMAP", comment: "Title for manual account IMAP setup")

        let nextButtonTittle = NSLocalizedString("Next", comment: "Next button title for manual account IMAP setup")
        setupView.nextButton.setTitle(nextButtonTittle, for: .normal)
        setupView.nextRightButton.setTitle(nextButtonTittle, for: .normal)

        let cancelButtonTittle = NSLocalizedString("Back", comment: "Cancel button title for manual account IMAP setup")
        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)
        setupView.cancelLeftButton.setTitle(cancelButtonTittle, for: .normal)

        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account IMAP setup")
        setupView.firstTextField.placeholder = userNamePlaceholder

        let serverPlaceholder = NSLocalizedString("Server", comment: "Server placeholder for manual account IMAP setup")
        setupView.secondTextField.placeholder = serverPlaceholder

        let portPlaceholder = NSLocalizedString("Port", comment: "Port placeholder for manual account IMAP setup")
        setupView.thirdTextField.placeholder = portPlaceholder

        let TransportSecurityPlaceholder = NSLocalizedString("Transport Security", comment: "TransportSecurity placeholder for manual account IMAP setup")
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
            sender.text = transport.localizedString()
            self.verifiableAccount?.transportIMAP = transport
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
        present(alertController, animated: true) {}
    }

    /// Update view state from view model
    /// - Parameter animated: this property only apply to  items with animations, list AnimatedPlaceholderTextFields
    private func updateView(animated: Bool = true) {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        guard let verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("No Verifiable account")
            return
        }
        setupView.firstTextField.set(text: verifiableAccount.loginNameIMAP,
                                     animated: animated)
        setupView.secondTextField.set(text: verifiableAccount.serverIMAP,
                                      animated: animated)
        setupView.thirdTextField.set(text: String(verifiableAccount.portIMAP),
                                     animated: animated)
        setupView.fourthTextField.set(text: verifiableAccount.transportIMAP.localizedString(),
                                      animated: animated)

        setupView.pEpSyncSwitch.isOn = verifiableAccount.keySyncEnable

        setupView.nextButton.isEnabled = verifiableAccount.isValidUser
        setupView.nextRightButton.isEnabled = verifiableAccount.isValidUser
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
