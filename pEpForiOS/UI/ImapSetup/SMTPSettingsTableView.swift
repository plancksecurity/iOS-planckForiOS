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

open class SMTPSettingsTableView: UITableViewController, TextfieldResponder, UITextFieldDelegate {
    let comp = "SMTPSettingsTableView"

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!

    var appConfig: AppConfig!
    var model: ModelUserInfoTable!
    var fields = [UITextField]()
    var responder = 0
    
    let viewWidthAligner = ViewWidthsAligner()
    let status = ViewStatus()
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("SMTP", comment: "Manual account setup")
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [serverValue, portValue]
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewWidthAligner.alignViews([
            serverTitle,
            portTitle
        ], parentView: view)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MessageModelConfig.accountDelegate = self
        updateView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        firstResponder(model.serverSMTP == nil)
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
        navigationItem.rightBarButtonItem?.isEnabled = !(status.activityIndicatorViewEnable)
    }

    func showErrorMessage (_ message: String) {
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

    func viewLog() {
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

    func verifyAccount() {
        self.status.activityIndicatorViewEnable =  true
        updateView()

        let identity = Identity.create(address: model.email!, userName: model.name!)
        identity.isMySelf = true
        let userName = (model.username ?? model.email)!

        let imapServer = Server.create(serverType: .imap, port: model.portIMAP,
                                       address: model.serverIMAP!,
                                       transport: model.transportIMAP.toServerTransport())
        imapServer.needsVerification = true

        let smtpServer = Server.create(serverType: .smtp, port: model.portSMTP,
                                       address: model.serverSMTP!,
                                       transport: model.transportSMTP.toServerTransport())
        smtpServer.needsVerification = true
        let credentials = ServerCredentials.create(userName: userName, password: model.password,
                                                   servers: [imapServer, smtpServer])
        credentials.needsVerification = true
        let account = Account.create(identity: identity, credentials: [credentials])
        account.needsVerification = true
        account.save()
    }

    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
        verifyAccount()
        hideKeybord()
    }
    
    func hideKeybord() {
        serverValue.resignFirstResponder()
        portValue.resignFirstResponder()
    }
    
    open func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }
}

extension SMTPSettingsTableView: AccountDelegate {
    public func didVerify(account: Account, error: NSError?) {
        GCD.onMain() {
            self.status.activityIndicatorViewEnable = false
            self.updateView()

            if let err = error {
                self.showErrorMessage(err.localizedDescription)
            } else {
                // unwind back to INBOX on success
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension SMTPSettingsTableView: SegueHandlerType {
    
   public enum SegueIdentifier: String {
    case noSegue
    case viewLogSegue
    }
}
