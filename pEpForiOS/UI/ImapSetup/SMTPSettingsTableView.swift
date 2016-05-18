//
//  SMTPSettingsTableView.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol SecondDataEnteredDelegate: class {
    func saveServerInformationSMTP(server:String?)
    func savePortInformationSMTP(port: UInt16?)
    func savePortTransportSMTP(transport: ConnectionTransport?)
}

class SMTPSettingsTableView: UITableViewController {
    let unwindToEmailListSegue = "unwindToEmailListSegue"

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    weak var delegate: SecondDataEnteredDelegate? = nil

    var appConfig: AppConfig?
    var model: ModelUserInfoTable?

    override func viewDidLoad() {
        super.viewDidLoad()
        serverValue.becomeFirstResponder()
        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model?.serverSMTP
        if (model!.portSMTP != nil) {
            portValue.text = String(model!.portSMTP!)
        }

        if let transport = model!.transportSMTP {
            switch transport {
            case .StartTLS:
                self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
            case .Plain:
                self.transportSecurity.setTitle("Plain >", forState: .Normal)
            default:
                self.transportSecurity.setTitle("TLS >", forState: .Normal)
            }
        } else {
            self.transportSecurity.setTitle("Plain >", forState: .Normal)
        }
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Security protocol", comment: ""),
            message: NSLocalizedString("Choose a Security protocol for your accont", comment: ""),
            preferredStyle: .ActionSheet)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(CancelAction)

        let StartTLSAction = UIAlertAction(title: "Start TLS", style: .Default) { (action) in
             self.model!.transportSMTP = ConnectionTransport.StartTLS
             self.delegate?.savePortTransportSMTP(ConnectionTransport.StartTLS)
             self.updateView()
        }
        alertController.addAction(StartTLSAction)
        let TLSAction = UIAlertAction(title: "TLS", style: .Default) { (action) in
            self.model!.transportSMTP = ConnectionTransport.TLS
            self.delegate?.savePortTransportSMTP(ConnectionTransport.TLS)
            self.updateView()
        }
        alertController.addAction(TLSAction)
        let NONEAction = UIAlertAction(title: "Plain", style: .Default) { (action) in
            self.model!.transportSMTP = ConnectionTransport.Plain
            self.delegate?.savePortTransportSMTP(ConnectionTransport.Plain)
            self.updateView()

        }
        alertController.addAction(NONEAction)
        self.presentViewController(alertController, animated: true) {}
    }

    @IBAction func enteredServer(sender: AnyObject) {
        model!.serverSMTP = serverValue.text!
        delegate?.saveServerInformationSMTP(serverValue.text!)
    }

    @IBAction func enteredPort(sender: AnyObject) {
        model!.portSMTP = UInt16(portValue.text!)
        delegate?.savePortInformationSMTP(UInt16(portValue.text!))
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }

    @IBAction func nextButtonTapped(sender: UIBarButtonItem) {
        let connect = ConnectInfo.init(
            email: model!.email!, imapPassword: model!.password!,
            imapServerName: model!.serverIMAP!, imapServerPort: model!.portIMAP!,
            imapTransport: model!.transportIMAP!, smtpServerName: model!.serverSMTP!,
            smtpServerPort: model!.portSMTP!, smtpTransport: model!.transportSMTP!)

        appConfig?.grandOperator.verifyConnection(connect, completionBlock: { error in
            if error == nil {
                GCD.onMain() {
                    // save account, check for error
                    if self.appConfig?.model.insertAccountFromConnectInfo(connect) != nil {
                        // unwind back to INBOX on success
                        self.performSegueWithIdentifier(self.unwindToEmailListSegue, sender: sender)
                    } else {
                        // TODO: Display error that account could not be saved
                    }
                }
            } else {
                // TODO: Display error message
            }
        })
    }
}