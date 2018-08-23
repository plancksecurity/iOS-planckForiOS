//
//  SMTPSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class SMTPSettingsTableViewController: BaseTableViewController, TextfieldResponder {
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!

    var model: AccountUserInput!
    private var currentlyVerifiedAccount: Account?
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
        firstResponder(model.serverSMTP == nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewWidthAligner.alignViews([serverTitle, portTitle], parentView: view)
    }

    // MARK: - Working Bees

    private func updateView() {
        serverValue.text = model.serverSMTP
        portValue.text = String(model.portSMTP)
        transportSecurity.setTitle(model.transportSMTP.localizedString(), for: UIControlState())

        if isCurrentlyVerifying {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        navigationItem.rightBarButtonItem?.isEnabled = !isCurrentlyVerifying
    }

    private func viewLog() {
        performSegue(withIdentifier: .viewLogSegue, sender: self)
    }

    /// Triggers verification for given data.
    ///
    /// - Throws: AccountVerificationError
    private func verifyAccount() throws {
        isCurrentlyVerifying =  true
        let account = try model.account()
        currentlyVerifiedAccount = account
        appConfig.messageSyncService.requestVerification(account: account, delegate: self)
    }

    private func informUser(about error: Error, title: String) {
        let alert = UIAlertController.pEpAlertController(
            title: title,
            message: error.localizedDescription,
            preferredStyle: UIAlertControllerStyle.alert)
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
            self.model.transportSMTP = transport
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
        model.serverSMTP = sender.text
    }

    @IBAction func changePort(_ sender: UITextField) {
        if let text = portValue.text {
            if let port = UInt16(text) {
                model.portSMTP = port
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

// MARK: - AccountVerificationServiceDelegate

extension SMTPSettingsTableViewController: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        if result == .ok {
            MessageModel.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                    return
                }
                guard let account = me.currentlyVerifiedAccount else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "We verified an non-existing account? " +
                        "Now what?")
                    return
                }
                account.save()
            }
        }
        GCD.onMain() {
            self.isCurrentlyVerifying =  false
            switch result {
            case .ok:
                // unwind back to INBOX or folder list on success
                self.performSegue(withIdentifier: .backToEmailListSegue, sender: self)
            case .imapError(let err):
                UIUtils.show(error: err, inViewController: self)
            case .smtpError(let err):
                UIUtils.show(error: err, inViewController: self)
            case .noImapConnectData, .noSmtpConnectData:
                let error = LoginViewController.LoginError.noConnectData
                UIUtils.show(error: error, inViewController: self)
            }
        }
    }
}

// MARK: - SegueHandlerType

extension SMTPSettingsTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case noSegue
        case viewLogSegue
        case backToEmailListSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .backToEmailListSegue:
            // nothing to do, since it's an unwind segue the targets already are configured
            break
        case .viewLogSegue:
            if let dnc = segue.destination as? UINavigationController,
                let dvc = dnc.rootViewController as? LogViewController {
                dvc.appConfig = appConfig
            }
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
