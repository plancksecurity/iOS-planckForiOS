//
//  SMTPSettingsTableView.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit


public class SMTPSettingsTableView: UITableViewController {
    let unwindToEmailListSegue = "unwindToEmailListSegue"

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    @IBOutlet weak var serverValueTextField: UILabel!
    @IBOutlet weak var portValueTextField: UILabel!

    var appConfig: AppConfig!
    var model: ModelUserInfoTable!

    let viewWidthAligner = ViewWidthsAligner()

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if model.serverSMTP == nil {
            serverValue.becomeFirstResponder()
        }
        portValue.keyboardType = UIKeyboardType.NumberPad
        updateView()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewWidthAligner.alignViews([serverValueTextField,
            portValueTextField], parentView: self.view)
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model.serverSMTP
        portValue.text = String(model.portSMTP)
        transportSecurity.setTitle(model.transportSMTP.localizedString(), forState: .Normal)
    }

    func showErrorMessage (message: String) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Error",
                comment: "the text in the title for the error message AlerView in account settings"),
            message:message, preferredStyle: .Alert)

        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok",
            comment: "confirmation button text for error message AlertView in account settings"),
            style: .Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Transport protocol",
                comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                comment: "UI alert message for transport protocol"),
            preferredStyle: .ActionSheet)

        let block: (ConnectionTransport) -> () = { transport in
            self.model.transportSMTP = transport
            self.updateView()
        }

        alertController.setupActionFromConnectionTransport(.Plain, block: block)
        alertController.setupActionFromConnectionTransport(.TLS, block: block)
        alertController.setupActionFromConnectionTransport(.StartTLS, block: block)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel for an alert view"),
            style: .Cancel) { (action) in}
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true) {}
    }

    @IBAction func changeServer(sender: UITextField) {
        model.serverSMTP = sender.text
    }

    @IBAction func changePort(sender: UITextField) {
        if let text = portValue.text {
            if let port = UInt16(text) {
                model.portSMTP = port
            }
        }
    }

    @IBAction func nextButtonTapped(sender: UIBarButtonItem) {
        let connect = ConnectInfo.init(
            email: model.email!, imapUsername: model.email!,
            smtpUsername: model.email!, imapPassword: model.password!,
            smtpPassword: model.password!, imapServerName: model.serverIMAP!,
            imapServerPort: model.portIMAP, imapTransport: model.transportIMAP,
            smtpServerName: model.serverSMTP!, smtpServerPort: model.portSMTP,
            smtpTransport: model.transportSMTP)

        appConfig?.grandOperator.verifyConnection(connect, completionBlock: { error in
            if error == nil {
                GCD.onMain() {
                    // save account, check for error
                    if self.appConfig?.model.insertAccountFromConnectInfo(connect) != nil {
                        // unwind back to INBOX on success
                        self.performSegueWithIdentifier(self.unwindToEmailListSegue, sender: sender)
                    } else {
                        self.showErrorMessage(NSLocalizedString("Could not save account", comment: ""))
                    }
                }
            } else {
                if let error = error?.localizedDescription {
                    self.showErrorMessage(error)
                } else {
                    self.showErrorMessage(NSLocalizedString("Could not connect", comment: ""))
                }
            }
        })
    }
}