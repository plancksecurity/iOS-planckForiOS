//
//  SMTPSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class SMTPSettingsTableViewController: BaseTableViewController, TextfieldResponder,
UITextFieldDelegate {
    let comp = "SMTPSettingsTableView"

    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!

    var model: AccountUserInput!
    var fields = [UITextField]()
    var responder = 0

    let viewWidthAligner = ViewWidthsAligner()
    var isCurrentlyVerifying = false {
        didSet {
            updateView()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("SMTP", comment: "Manual account setup")
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [serverValue, portValue]
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        viewWidthAligner.alignViews([
            serverTitle,
            portTitle
            ], parentView: view)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        firstResponder(model.serverSMTP == nil)
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

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

    private func showErrorMessage (_ message: String) {
        let alertView = UIAlertController.pEpAlertController(
            title: NSLocalizedString("Error",
                                     comment: "the text in the title for the error message AlerView in account settings"),
            message:message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "View log",
                comment: "Button for viewing the log on error"),
            style: .default, handler: { action in
                self.viewLog()
        }))
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "Ok",
                comment: "confirmation button text for error message AlertView in account settings"),
            style: .default, handler: nil))
        present(alertView, animated: true, completion: nil)
    }

    private func viewLog() {
        performSegue(withIdentifier: .viewLogSegue, sender: self)
    }

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

    /// Creates and persits an account with given data and triggers a verification request.
    ///
    /// - Parameter model: account data
    /// - Throws: AccountVerificationError
    private func verifyAccount() throws {
        isCurrentlyVerifying =  true
        do {
            let account = try model.account()
            account.save()
            appConfig.messageSyncService.requestVerification(account: account, delegate: self)
        } catch {
            throw error
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

    public func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .backToEmailListSegue:
            guard
                let destination = segue.destination as? EmailListViewController
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Problem casting DVC")
                    return
            }
            destination.appConfig = self.appConfig
        case .viewLogSegue:
            if let dnc = segue.destination as? UINavigationController,
                let dvc = dnc.rootViewController as? LogViewController {
                dvc.appConfig = appConfig
            }
        default:()
        }
    }
}

extension SMTPSettingsTableViewController: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        GCD.onMain() {
            self.isCurrentlyVerifying =  false
            switch result {
            case .ok:
                // unwind back to INBOX on success
                self.performSegue(withIdentifier: .backToEmailListSegue, sender: self)
            case .imapError(let err):
                self.showErrorMessage(err.localizedDescription)
            case .smtpError(let err):
                self.showErrorMessage(err.localizedDescription)
            case .noImapConnectData, .noSmtpConnectData:
                self.showErrorMessage(
                    LoginTableViewControllerError.noConnectData.localizedDescription)
            }
        }
    }
}

extension SMTPSettingsTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case noSegue
        case viewLogSegue
        case backToEmailListSegue
    }
}
