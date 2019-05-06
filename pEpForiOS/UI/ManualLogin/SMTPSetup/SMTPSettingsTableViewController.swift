//
//  SMTPSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel
import PantomimeFramework

class SMTPSettingsTableViewController: BaseTableViewController, TextfieldResponder {
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!

    var model: VerifiableAccountProtocol?
    var fields = [UITextField]()
    var responder = 0

    let viewWidthAligner = ViewWidthsAligner()
    var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    // MARK: - Life Cylcle

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("SMTP", comment: "Manual account setup")
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [serverValue, portValue]
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(model?.serverSMTP == nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewWidthAligner.alignViews([serverTitle, portTitle], parentView: view)
    }

    // MARK: - Working Bees

    private func updateView() {
        serverValue.text = model?.serverSMTP
        if let thePort = model?.portSMTP {
            portValue.text = String(thePort)
        }
        transportSecurity.setTitle(model?.transportSMTP.localizedString(), for: UIControl.State())

        if isCurrentlyVerifying {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
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
        serverValue.resignFirstResponder()
        portValue.resignFirstResponder()
    }

    // MARK: - Actions

    @IBAction func alertWithSecurityValues(_ sender: UIButton) {
        let alertController = UIAlertController.pEpAlertController(
            title: NSLocalizedString("Transport protocol",
                                     comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                                       comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)
        let block: (ConnectionTransport) -> () = { transport in
            self.model?.transportSMTP = transport
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
        self.present(alertController, animated: true) {}
    }

    @IBAction func changeServer(_ sender: UITextField) {
        model?.serverSMTP = sender.text
    }

    @IBAction func changePort(_ sender: UITextField) {
        if let text = portValue.text {
            if let port = UInt16(text) {
                model?.portSMTP = port
            }
        }
    }

    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
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
}

// MARK: - SegueHandlerType

extension SMTPSettingsTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
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

// MARK: - UITextFieldDelegate

extension SMTPSettingsTableViewController: UITextFieldDelegate {

    public func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }
}

extension SMTPSettingsTableViewController: VerifiableAccountDelegate {
    func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
                MessageModelUtil.performAndWait { [weak self] in
                    do {
                        try self?.model?.save()
                    } catch {
                        Logger.frontendLogger.log(error: error)
                        Logger.frontendLogger.errorAndCrash(
                            "Unexpected error on saving the account")
                    }
                }
                GCD.onMain() {  [weak self] in
                    self?.isCurrentlyVerifying = false
                    self?.performSegue(withIdentifier: .backToEmailListSegue, sender: self)
            }
        case .failure(let error):
            GCD.onMain() { [weak self] in
                if let theSelf = self {
                    theSelf.isCurrentlyVerifying = false
                    UIUtils.show(error: error, inViewController: theSelf)
                }
            }
        }
    }
}
