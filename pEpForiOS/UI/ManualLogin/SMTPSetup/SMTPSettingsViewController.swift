//
//  SMTPSettingsViewController.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox
import MessageModel
import PantomimeFramework

final class SMTPSettingsViewController: UIViewController, TextfieldResponder {

    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    public var viewModel : SMTPSettingsViewModel?

    internal var fields = [UITextField]()

    internal var responder = 0

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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        firstResponder(vm.verifiableAccount.loginNameSMTP == nil)
    }

    @IBAction private func didTapOnView(_ sender: Any) {
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
        if textField == setupView.fifthTextField {
            view.endEditing(true)
            presentActionSheetWithTransportSecurityValues(textField)
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
        if textField == setupView.fourthTextField {
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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleDidPressNextButton()
    }

    // Username
    func didChangeFirst(_ textField: UITextField) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        vm.verifiableAccount.loginNameSMTP = textField.text
        updateView()
    }

    // Password
    func didChangeSecond(_ textField: UITextField) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        vm.verifiableAccount.smtpPassword = textField.text
    }

    // Server
    func didChangeThird(_ textField: UITextField) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        vm.verifiableAccount.serverSMTP = textField.text
    }

    // Port
    func didChangeFourth(_ textField: UITextField) {
        guard let text = textField.text,
              let port = UInt16(text) else {
            //If not UInt16 then do nothing. Example empty string
            return
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.verifiableAccount.portSMTP = port
    }

    // Transport security
    func didChangeFifth(_ textField: UITextField) {
        //Do nothing, changes are saved in model and textField in the block of alert.
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

// MARK: - SMTPSettingsDelegate

extension SMTPSettingsViewController: SMTPSettingsDelegate {

    /// Update view state from view model
    /// - Parameter animated: this property only apply to  items with animations, list AnimatedPlaceholderTextFields
    func updateView(animated: Bool = true) {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }


        setupView.firstTextField.set(text: vm.verifiableAccount.loginNameSMTP,
                                     animated: animated)
        setupView.secondTextField.set(text: vm.verifiableAccount.smtpPassword,
                                      animated: animated)
        setupView.thirdTextField.set(text: vm.verifiableAccount.serverSMTP,
                                     animated: animated)
        setupView.fourthTextField.set(text: String(vm.verifiableAccount.portSMTP),
                                      animated: animated)
        setupView.fifthTextField.set(text: vm.verifiableAccount.transportSMTP.localizedString(),
                                     animated: animated)

        setupView.pEpSyncSwitch.isOn = vm.verifiableAccount.keySyncEnable

        setupView.nextButton.isEnabled = vm.verifiableAccount.isValidUser
        setupView.nextRightButton.isEnabled = vm.verifiableAccount.isValidUser

        vm.handleLoading()
        navigationItem.rightBarButtonItem?.isEnabled = !vm.isCurrentlyVerifying
        let primary = UIColor.primary()
        view.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .systemBackground : primary
    }

    func hideKeyboard() {
        view.endEditing(true)
    }

    func accountVerifiedSuccessfully() {
        performSegue(withIdentifier: .backToEmailListSegue, sender: self)
    }

    func showError(error: Error) {
        UIUtils.show(error: error)
    }

    func inform(message: String, title: String) {
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message)
    }
}

//MARK: - Private

extension SMTPSettingsViewController {

    private func setUpContainerView() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            Log.shared.errorAndCrash("Fail to get manualAccountSetupView")
            return
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            setupView.scrollView.isScrollEnabled = false
        }
    }

    private func presentActionSheetWithTransportSecurityValues(_ sender: UITextField) {
        let title = NSLocalizedString("Transport protocol",
                                 comment: "UI alert title for transport protocol")
        let message = NSLocalizedString("Choose a Security protocol for your accont",
                                   comment: "UI alert message for transport protocol")
        let alertController = UIUtils.actionSheet(title: title, message: message)
        let transportBlock: (ConnectionTransport) -> () = { [weak self] transport in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let vm = me.viewModel else {
                Log.shared.errorAndCrash("VM not found")
                return
            }

            vm.verifiableAccount.transportSMTP = transport
            sender.text = transport.localizedString()
        }

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sender
            popoverPresentationController.sourceRect = sender.bounds
        }

        alertController.setupActionFromConnectionTransport(.plain, block: transportBlock)
        alertController.setupActionFromConnectionTransport(.TLS, block: transportBlock)
        alertController.setupActionFromConnectionTransport(.startTLS, block: transportBlock)

        let actionTitle = NSLocalizedString("Cancel", comment: "Cancel for an alert view")
        let cancelAction = UIUtils.action(actionTitle, .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func setUpTextFieldsInputTraits() {
        guard let setupView = manualAccountSetupContainerView.setupView else {
            //Error handle in setupView getter
            return
        }

        setupView.fourthTextField.keyboardType = .numberPad
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

        let passwordPlaceholder = NSLocalizedString("Password", comment: "Password placeholder for manual account SMTP setup")
        setupView.secondTextField.placeholder = passwordPlaceholder
        setupView.secondTextField.isSecureTextEntry = true

        let serverPlaceholder = NSLocalizedString("Server", comment: "Server placeholder for manual account SMTP setup")
        setupView.thirdTextField.placeholder = serverPlaceholder

        let portPlaceholder = NSLocalizedString("Port", comment: "Port placeholder for manual account SMTP setup")
        setupView.fourthTextField.placeholder = portPlaceholder

        let transportSecurityPlaceholder = NSLocalizedString("Transport Security", comment: "TransportSecurity placeholder for manual account SMTP setup")
        setupView.fifthTextField.placeholder = transportSecurityPlaceholder
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            view.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .systemBackground : UIColor.primaryDarkMode
            manualAccountSetupContainerView.backgroundColor = view.backgroundColor
            manualAccountSetupContainerView.setupView?.backgroundColor = view.backgroundColor
            view.layoutSubviews()
            view.layoutIfNeeded()
        }
    }
}
