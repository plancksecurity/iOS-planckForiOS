//
//  SMTPSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

//BUFF: replace open with public also in previous views (make other accesses also as strict as possible)
public class ViewStatus {
    public var activityIndicatorViewEnable = false
}

public class SMTPSettingsTableViewController: UITableViewController, TextfieldResponder,
UITextFieldDelegate {
    let comp = "SMTPSettingsTableView"

    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!

    var appConfig: AppConfig?
    var model: AccountUserInput!
    var fields = [UITextField]()
    var responder = 0

    let viewWidthAligner = ViewWidthsAligner()
    let status = ViewStatus()


    public override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("SMTP", comment: "Manual account setup")
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

        if status.activityIndicatorViewEnable {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        navigationItem.rightBarButtonItem?.isEnabled = !(status.activityIndicatorViewEnable)
    }

    fileprivate func showErrorMessage (_ message: String) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Error",
                                     comment: "the text in the title for the error message AlerView in account settings"),
            message:message, preferredStyle: .alert)
        alertView.view.tintColor = .pEpGreen
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
        let alertController = UIAlertController(
            title: NSLocalizedString("Transport protocol",
                                     comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                                       comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)
        alertController.view.tintColor = .pEpGreen
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

    //BUFF: check for accidental server duplication
    private func verifyAccount() throws {
        self.status.activityIndicatorViewEnable =  true
        updateView()
        guard let ms = appConfig?.messageSyncService else {
            Log.shared.errorAndCrash(component: #function, errorString: "no MessageSyncService")
            return
        }
        do {
            let account = try model.account()
            account.needsVerification = true
            account.save()
            ms.requestVerification(account: account, delegate: self)
        } catch {
            throw error
        }
    }

    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
        do {
            try verifyAccount()
            hideKeybord()
        } catch {
            //BUFF: handle error
        }
        //        verifyAccount()
        //        hideKeybord()
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
}

extension SMTPSettingsTableViewController: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        GCD.onMain() {
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
