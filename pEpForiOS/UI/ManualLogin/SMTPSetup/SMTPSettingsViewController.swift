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

class SMTPSettingsViewController: UIViewController {}

//final class SMTPSettingsViewController: BaseTableViewController, TextfieldResponder {
//    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!
//
//    /// - Note: This VC doesn't have a view model yet, so this is used for the model.
//    var model: VerifiableAccountProtocol?
//
//    var fields = [UITextField]()
//    var responder = 0
//
//    let viewWidthAligner = ViewWidthsAligner()
//    var isCurrentlyVerifying = false {
//        didSet {
//            updateView()
//        }
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        UIHelper.variableCellHeightsTableView(tableView)
//        fields = manualAccountSetupContainerView.manualSetupViewTextFeilds()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        updateView()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        firstResponder(model?.serverSMTP == nil)
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        viewWidthAligner.alignViews([serverTitle, portTitle], parentView: view)
//    }
//
//    // MARK: - Working Bees
//
//
//
//    // MARK: - Actions
//
//    @IBAction func alertWithSecurityValues(_ sender: UIButton) {
//        let alertController = UIAlertController.pEpAlertController(
//            title: NSLocalizedString("Transport protocol",
//                                     comment: "UI alert title for transport protocol"),
//            message: NSLocalizedString("Choose a Security protocol for your accont",
//                                       comment: "UI alert message for transport protocol"),
//            preferredStyle: .actionSheet)
//        let block: (ConnectionTransport) -> () = { transport in
//            self.model?.transportSMTP = transport
//            self.updateView()
//        }
//
//        if let popoverPresentationController = alertController.popoverPresentationController {
//            popoverPresentationController.sourceView = sender
//        }
//
//        alertController.setupActionFromConnectionTransport(.plain, block: block)
//        alertController.setupActionFromConnectionTransport(.TLS, block: block)
//        alertController.setupActionFromConnectionTransport(.startTLS, block: block)
//
//        let cancelAction = UIAlertAction(
//            title: NSLocalizedString("Cancel", comment: "Cancel for an alert view"),
//            style: .cancel) { (action) in}
//        alertController.addAction(cancelAction)
//        self.present(alertController, animated: true) {}
//    }
//
//    @IBAction func changeServer(_ sender: UITextField) {
//        model?.serverSMTP = sender.text
//    }
//
//    @IBAction func changePort(_ sender: UITextField) {
//        if let text = portValue.text {
//            if let port = UInt16(text) {
//                model?.portSMTP = port
//            }
//        }
//    }
//
//    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
//        do {
//            try verifyAccount()
//            hideKeybord()
//        } catch {
//            let errorTopic = NSLocalizedString("Empty Field",
//                                               comment: "Title of alert: a required field is empty")
//            isCurrentlyVerifying =  false
//            informUser(about: error, title: errorTopic)
//        }
//    }
//}
//
//// MARK: - SegueHandlerType
//
//extension SMTPSettingsViewController: SegueHandlerType {
//    enum SegueIdentifier: String {
//        case noSegue
//        case backToEmailListSegue
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        switch segueIdentifier(for: segue) {
//        case .backToEmailListSegue:
//            // nothing to do, since it's an unwind segue the targets already are configured
//            break
//        default:()
//        }
//    }
//}
//
//// MARK: - UITextFieldDelegate
//
//extension SMTPSettingsViewController: UITextFieldDelegate {
//
//    func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
//        nextResponder(textfield)
//        return true
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        changedResponder(textField)
//    }
//}
//
//// MARK: - VerifiableAccountDelegate
//
//extension SMTPSettingsViewController: VerifiableAccountDelegate {
//    func didEndVerification(result: Result<Void, Error>) {
//        switch result {
//        case .success(()):
//            do {
//                try model?.save() { [weak self] success in
//                    DispatchQueue.main.async { [weak self] in
//                        guard let me = self else {
//                            Log.shared.errorAndCrash("Lost MySelf")
//                            return
//                        }
//
//                        switch success {
//
//                        case true:
//                            me.isCurrentlyVerifying = false
//                            me.performSegue(withIdentifier: .backToEmailListSegue, sender: me)
//
//                        case false:
//                            me.isCurrentlyVerifying = false
//                            UIUtils.show(error: VerifiableAccountValidationError.invalidUserData, inViewController: me)
//                        }
//                    }
//                }
//            } catch {
//                Log.shared.errorAndCrash(error: error)
//            }
//        case .failure(let error):
//            DispatchQueue.main.async { [weak self] in
//                guard let me = self else {
//                    Log.shared.errorAndCrash("Lost MySelf")
//                    return
//                }
//                me.isCurrentlyVerifying = false
//                UIUtils.show(error: error, inViewController: me)
//            }
//        }
//    }
//}
//
//// MARK: - Private
//
//extension SMTPSettingsViewController {
//    private func updateView() {
//        serverValue.text = model?.serverSMTP
//        if let thePort = model?.portSMTP {
//            portValue.text = String(thePort)
//        }
//        transportSecurity.setTitle(model?.transportSMTP.localizedString(), for: UIControl.State())
//
//        if isCurrentlyVerifying {
//            activityIndicatorView.startAnimating()
//        } else {
//            activityIndicatorView.stopAnimating()
//        }
//        navigationItem.rightBarButtonItem?.isEnabled = !isCurrentlyVerifying
//    }
//
//    /// Triggers verification for given data.
//    ///
//    /// - Throws: AccountVerificationError
//    private func verifyAccount() throws {
//        isCurrentlyVerifying =  true
//        model?.verifiableAccountDelegate = self
//        try model?.verify()
//    }
//
//    private func informUser(about error: Error, title: String) {
//        let alert = UIAlertController.pEpAlertController(
//            title: title,
//            message: error.localizedDescription,
//            preferredStyle: UIAlertController.Style.alert)
//        let cancelAction = UIAlertAction(title:
//            NSLocalizedString("OK", comment: "OK button for invalid accout settings user input alert"),
//                                         style: .cancel, handler: nil)
//        alert.addAction(cancelAction)
//        present(alert, animated: true)
//    }
//
//    private func hideKeybord() {
//        serverValue.resignFirstResponder()
//        portValue.resignFirstResponder()
//    }
//
//    private func setUpTextFieldsInputTraits() {
//        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
//            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
//            return
//        }
//
//        setupView.thirdTextField.keyboardType = .numberPad
//    }
//
//    private func setUpViewLocalizableTexts() {
//        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
//            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
//            return
//        }
//
//        setupView.titleLabel.text = NSLocalizedString("SMTP", comment: "Title manual account SMTP setup")
//
//        let nextButtonTittle = NSLocalizedString("Finish", comment: "Finish button title for manual account SMTP setup")
//        setupView.nextButton.setTitle(nextButtonTittle, for: .normal)
//
//        let cancelButtonTittle = NSLocalizedString("Back", comment: "Cancel button title for manual account SMTP setup")
//        setupView.cancelButton.setTitle(cancelButtonTittle, for: .normal)
//
//        let userNamePlaceholder = NSLocalizedString("User Name", comment: "User Name placeholder for manual account SMTP setup")
//        setupView.firstTextField.placeholder = userNamePlaceholder
//
//        let serverPlaceholder = NSLocalizedString("Server", comment: "Server placeholder for manual account SMTP setup")
//        setupView.secondTextField.placeholder = serverPlaceholder
//
//        let portPlaceholder = NSLocalizedString("Port", comment: "Port placeholder for manual account SMTP setup")
//        setupView.thirdTextField.placeholder = portPlaceholder
//
//        let TransportSecurityPlaceholder = NSLocalizedString("TransportSecurity", comment: "TransportSecurity placeholder for manual account SMTP setup")
//        setupView.fourthTextField.placeholder = TransportSecurityPlaceholder
//    }
//}
