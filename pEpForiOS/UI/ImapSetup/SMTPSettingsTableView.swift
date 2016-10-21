//
//  SMTPSettingsTableView.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class ViewStatus {
    open var activityIndicatorViewEnable = false
}

open class SMTPSettingsTableView: UITableViewController {
    let comp = "SMTPSettingsTableView"
    let unwindToEmailListSegue = "unwindToEmailListSegue"

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverValueTextField: UILabel!
    @IBOutlet weak var portValueTextField: UILabel!

    var appConfig: AppConfig!
    var model: ModelUserInfoTable!

    let viewWidthAligner = ViewWidthsAligner()
    let status = ViewStatus()

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if model.serverSMTP == nil {
            serverValue.becomeFirstResponder()
        }
        portValue.keyboardType = UIKeyboardType.numberPad
        updateView()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWidthAligner.alignViews([serverValueTextField,
            portValueTextField], parentView: self.view)
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model.serverSMTP
        portValue.text = String(model.portSMTP)
        transportSecurity.setTitle(model.transportSMTP.localizedString(), for: UIControlState())
        if status.activityIndicatorViewEnable {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = !(status.activityIndicatorViewEnable)
    }

    func showErrorMessage (_ message: String) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Error",
                comment: "the text in the title for the error message AlerView in account settings"),
            message:message, preferredStyle: .alert)

        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok",
            comment: "confirmation button text for error message AlertView in account settings"),
            style: .default, handler: nil))
        present(alertView, animated: true, completion: nil)
    }

    @IBAction func alertWithSecurityValues(_ sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Transport protocol",
                comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)

        let block: (ConnectionTransport) -> () = { transport in
            self.model.transportSMTP = transport
            self.updateView()
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

    func verifyAccountOldStyle(_ sender: UIBarButtonItem) {
        let connect = ImapSmtpConnectInfo.init(
            nameOfTheUser: model.name!,
            email: model.email!, imapUsername: model.email!,
            smtpUsername: model.email!, imapPassword: model.password!,
            smtpPassword: model.password!, imapServerName: model.serverIMAP!,
            imapServerPort: model.portIMAP, imapTransport: model.transportIMAP,
            smtpServerName: model.serverSMTP!, smtpServerPort: model.portSMTP,
            smtpTransport: model.transportSMTP)

        self.status.activityIndicatorViewEnable =  true
        updateView()
        appConfig?.grandOperator.verifyConnection(connect, completionBlock: { error in
            self.status.activityIndicatorViewEnable = false
            self.updateView()

            guard let err = error else {
                GCD.onMain() {
                    // save account, check for error
                    guard let model = self.appConfig?.model else {
                        self.showErrorMessage(
                            String(format:
                                NSLocalizedString("Internal Error: %d",
                                                  comment: "Internal error display, with error number"),
                                   Constants.InternalErrorCode.noModel.rawValue))
                        Log.warnComponent(self.comp, "Could not access model")
                        return
                    }

                    let account = model.insertAccountFromImapSmtpConnectInfo(connect)
                    let contact = model.insertOrUpdateContactEmail(account.email,
                                                                   name: account.nameOfTheUser)

                    // Mark that contact as mySelf
                    contact.isMySelf = NSNumber.init(booleanLiteral: true)

                    model.save()

                    // unwind back to INBOX on success
                    self.performSegue(withIdentifier: self.unwindToEmailListSegue, sender: sender)
                }
                return
            }
            self.showErrorMessage(err.localizedDescription)
        })
    }

    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
        self.status.activityIndicatorViewEnable =  true
        updateView()

        let user = Identity.create(address: model.email!, userName: model.name!, userID: nil)
        user.isMySelf = true
        let userName = (model.username ?? model.email)!
        let imapServer = Server.create(serverType: .imap, port: model.portIMAP,
                                       address: model.serverIMAP!, userName: userName,
                                       transport: model.transportIMAP.toServerTransport())
        let smtpServer = Server.create(serverType: .smtp, port: model.portSMTP,
                                       address: model.serverSMTP!, userName: userName,
                                       transport: model.transportSMTP.toServerTransport())
        let account = Account.create(user: user, servers: [imapServer, smtpServer])
        account.needsVerification = true
        account.save()
    }
}

extension SMTPSettingsTableView: AccountDelegate {
    public func didVerifyAccount(_ account: Account, error: NSError?) {
        self.status.activityIndicatorViewEnable = false
        self.updateView()

        if let err = error {
            self.showErrorMessage(err.localizedDescription)
        } else {
            GCD.onMain() {
                // unwind back to INBOX on success
                self.performSegue(withIdentifier: self.unwindToEmailListSegue, sender: nil)
            }
        }
    }
}
